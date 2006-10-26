namespace "bbc" do
  require 'open-uri'
  require 'simple-rss'
  require 'zget'
  require 'bbcnews'
  require 'digest'
  require 'htmldiff'
  require 'news_page'
  include HTMLDiff
  include BBCNews
    
  @thread_rss_url = "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/talking_point/rss.xml"
  @comments_rss_url = "http://newsforums.bbc.co.uk/nol/rss/rssmessages.jspa?threadID=%s&lang=en"
  @comments_html_url = "http://newsforums.bbc.co.uk/nol/thread.jspa?threadID=%s"

  @logger = Logger.new("log/#{RAILS_ENV}-rake.log")
  
  def log_debug(msg)
  	time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
  	@logger.info(msg)
    puts msg
  end

  def log_info(msg)
  	time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
  	@logger.info(msg)
    puts msg
  end
	
  def log_error(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
    @logger.error(msg)
    puts msg
  end
	
  def log_warn(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
    @logger.warn(msg)
    puts msg
  end

  def head_hash(url)
    t = url.scan /http:\/\/([^\/]+)\/(.*)$/
    host = t.first.first
    path = t.first.last
    Net::HTTP.start(host, 80) do |http|
      begin
        @response = http.head('/'+path)
      rescue Timeout::Error
				log_warn("head_hash: Timeout::Error on #{url}")
        return false
      end
    end
    @response.to_hash
  end
  
  def remote_filesize(url)
    r = head_hash(url)
    return false unless r and r.has_key? 'content-length'
    r['content-length'].first.to_i
  end

  def remote_etag(url)
    r = head_hash(url)
    return false unless r and r.has_key? 'etag'
    r['etag']
  end

  def thread_id(link)
      la = link.scan(/^.*threadID=([0-9]+).*$/)
      return false unless la
      la = la.first
      return false unless la
      la.first
  end
  
  def get_rss_entries(url)
    rssdata = zget(url)
    begin
      rss = SimpleRSS.parse(rssdata)
      entries = rss.entries
    rescue SimpleRSSError
      log_error("RSS malformed: #{url}")
      entries = []
    end
    return entries
  end

  desc "find any new BBC Hys threads"
  task :getnewthreads => :environment do
      
    rssdata = zget(@thread_rss_url)

    begin
      rss = SimpleRSS.parse rssdata
    rescue SimpleRSSError
        log_error "getnewthreads: error parsing RSS #{@thread_rss_url}"
        exit
    end
    rss.entries.each do |e|
      begin
        link = e[:link]
        thread_id = thread_id(link)
        next unless thread_id
        next if HysThread.find_by_bbcid(thread_id)
        log_info "getnewthreads: new hysthread: #{thread_id}"
        t = HysThread.new
        t.title = e[:title]
        t.bbcid = thread_id
        t.created_at = Time.parse( e[:pubDate].to_s )
        t.save
      rescue NameError
        log_info "getnewthreads: RSS entry didn't look right"
        next
      end
    end
  end   
  
	def get_new_comments(find_conditions)
    # FIXME: this should be condition on updated_at, once the data is sorted out
    HysThread.find(:all, :order => 'created_at desc', :conditions => find_conditions ).each do |t|
      url = @comments_rss_url.gsub('%s', t.bbcid.to_s)
      log_debug "hysthread:#{t.bbcid} title: '#{t.title}'"
      newsize = remote_filesize(url)
			if newsize
				log_debug "hysthread:#{t.bbcid} - content-length header exists"
			else	
	      begin
	        rssdata = zget(url)
	      rescue OpenURI::HTTPError => e
					log_error("hysthread:#{t.bbcid}: #{e.to_s}")
	        next
	      end
      	newsize = rssdata.size
			end
      lastsize = t.rsssize
      if lastsize.to_i == newsize.to_i
        log_debug "hysthread:#{t.bbcid} - no change in comments rss"
        next
      end
			log_info("hysthread:#{t.bbcid} - comments rss updated - #{t.title}")
      t.rsssize = newsize
			if rssdata.nil?
				rssdata = zget(url)
			end
      begin
          rss = SimpleRSS.parse rssdata
      rescue SimpleRSSError => e
					log_error("hysthread:#{t.bbcid} - error parsing comments rss: #{e.to_s}")
          next
      end
      if !t.last_rss_pubdate.nil? and rss.pubDate < t.last_rss_pubdate
        log_info("hysthread:#{t.bbcid} - rss pubDate older than last time, ignoring (#{rss.pubDate} < #{t.last_rss_pubdate})")
        next
      end
      t.last_rss_pubdate = rss.pubDate
      t.save
      comments = rss.entries.collect { |e| Haveyoursaycomment.instantiate_from_rss(e, t.bbcid) }
        
      oldest_comment = Time.now
      comments.each { |c| oldest_comment = c.modified if c.modified < oldest_comment }
        
			log_info("hysthread:#{t.bbcid}: #{comments.size} comments in rss, oldest: #{oldest_comment}, #{t.hys_comments.count} in database")

      comment_ids = t.comment_ids_since(oldest_comment)
      censored_ids = t.censored_comment_ids_since(oldest_comment)
      rss_ids = comments.collect { |c| c.message_id.to_i }
      rss_ids_size = rss_ids.size

      new_count = 0
      comments.each do |c|
          next if comment_ids.include?(c.message_id.to_i)
					log_info("hysthread:#{t.bbcid}: new comment #{c.message_id} created at #{c.created} by #{c.author}")
          new_count += 1
          nc = HysComment.new
          nc.text = c.text
          nc.author = c.author
          nc.modified_at = c.modified
          nc.created_at = c.created
          nc.bbcid = c.message_id
          t.hys_comments << nc
      end
      log_info "hysthread:#{t.bbcid} - #{new_count} new comments" if new_count > 0

      rss_ids.each do |cid|
        next unless censored_ids.include?(cid)
        c = HysComment.find_by_bbcid(cid)
        c.censored = 1
        c.save
				log_info("thread #{t.bbcid}: missing comment #{c.bbcid} reappeared, created at  #{c.created_at} by #{c.author}")
      end  

			skip_count = 0
      comment_ids.each do |cid|
          next if rss_ids.include?(cid)
          next if censored_ids.include?(cid)
          c = HysComment.find_by_bbcid(cid)
          # due to the 1 second granularity, we can't regard missing comments with the same timestamp
          # as the oldest_comment as actually missing, if the rss feed is maxed out
          if rss_ids_size >= 500
            if c.modified_at = oldest_comment
							skip_count += 1
							next
						end
          end
					log_info("thread #{t.bbcid}: new missing comment #{c.bbcid}, created at  #{c.created_at} by #{c.author}")
          c.censored = 0
          c.save
      end
			log_info("thread #{t.bbcid}: skipped #{skip_count} comments at end of maxed out rss feed (dated #{oldest_comment}), due to time granularity") if skip_count > 0
    end
  end
  
	desc "read new HYS comments and check for censored ones"
  task :getnewcomments => :environment do
		get_new_comments(['created_at >= now() - INTERVAL 1 month'])
	end

	desc "check for censored HYS comments on the very latest threads"
	task :get_short_comments => :environment do
		log_info("get_short_comments started")
		get_new_comments(['created_at >= now() - INTERVAL 2 day'])
	end
	
	desc "check for censored HYS comments on the medium term threads"
	task :get_medium_comments => :environment do
		log_info("get_medium_comments started")
		get_new_comments(['created_at < now() - INTERVAL 2 day and created_at >= now() - INTERVAL 7 day'])
	end
	
	desc "check for censored HYS comments on the long term threads"
	task :get_long_comments => :environment do
		log_info("get_long_comments started")
		get_new_comments(['created_at < now() - INTERVAL 7 day and created_at >= now() - INTERVAL 2 month'])
	end

end
