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

  @logger = Logger.new('log/newsniffer-bbchys.log')

  def log_info(msg)
  	time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
  	@logger.info("#{time}: #{msg}")
  end
	
  def log_error(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    @logger.error("#{time}: #{msg}")
  end
	
  def log_warn(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    @logger.warn("#{time}: #{msg}")
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

  desc "check for new hys threads"
  task :checknewthreads => :environment do
    lastsize = Variable.geti('thread_rss_filesize')
    newsize = remote_filesize(@thread_rss_url)
    if lastsize.to_i == newsize.to_i
      print "no change in rss\n"
    else
      print "rss updated\n"
      Variable.put('thread_rss_filesize', newsize)
      Rake::Task[:getnewthreads].invoke
    end
  end

  desc "find any new threads"
  task :getnewthreads => :environment do
      
    rssdata = zget(@thread_rss_url)

    begin
      rss = SimpleRSS.parse rssdata
    rescue SimpleRSSError
        print "error parsing rss\n"
        exit
    end
    rss.entries.each do |e|
      begin
        link = e[:link]
        thread_id = thread_id(link)
        next unless thread_id
        next if HysThread.find_by_bbcid(thread_id)
        print "new thread: #{thread_id}\n"
        t = HysThread.new
        t.title = e[:title]
        t.bbcid = thread_id
        t.created_at = Time.parse( e[:pubDate].to_s )
        t.save
      rescue NameError
        print "skipping. RSS entry didn't look right\n"
        next
      end
    end
  end   
  
	def get_new_comments(find_conditions)
    # FIXME: this should be condition on updated_at, once the data is sorted out
    HysThread.find(:all, :order => 'created_at desc', :conditions => find_conditions ).each do |t|
      url = @comments_rss_url.gsub('%s', t.bbcid.to_s)
      print "id: #{t.bbcid} title: '#{t.title}'\n"
      #print "url: #{url}\n"
      newsize = remote_filesize(url)
			if newsize
				print " * content-length header exists\n"
			else	
	      begin
	        rssdata = zget(url)
	      rescue OpenURI::HTTPError
	        print " ! 404 error, skipping"
					log_error("thread #{t.bbcid}: 404 error")
	        next
	      end
      	newsize = rssdata.size
			end
      lastsize = t.rsssize
      if lastsize.to_i == newsize.to_i
        print " * no change in comments rss\n"
        next
      end
			log_info("thread #{t.bbcid}: comments rss updated - #{t.title}")
      print " * comments rss updated\n"
      t.rsssize = newsize
      t.save
			if rssdata.nil?
				rssdata = zget(url)
			end
      begin
          rss = SimpleRSS.parse rssdata
      rescue SimpleRSSError
          print " ! error parsing rss, skipping\n"
					@logger.error("thread #{t.bbcid}: error passing comments rss")
          next
      end
      comments = rss.entries.collect { |e| Haveyoursaycomment.instantiate_from_rss(e, t.bbcid) }
        
      oldest_comment = Time.now
      comments.each { |c| oldest_comment = c.modified if c.modified < oldest_comment }
        
      print " * #{comments.size} comments, oldest: #{oldest_comment}\n"
			log_info("thread #{t.bbcid}: #{comments.size} comments in rss, #{t.hys_comments.count} in database")

      comment_ids = t.comment_ids_since(oldest_comment)
      censored_ids = t.censored_comment_ids_since(oldest_comment)
      rss_ids = comments.collect { |c| c.message_id.to_i }
      rss_ids_size = rss_ids.size

      new_count = 0
      comments.each do |c|
          next if comment_ids.include?(c.message_id.to_i)
          #print " * new comment: #{c.message_id}: #{c.modified}\n"
					log_info("thread #{t.bbcid}: new comment #{c.message_id} created at #{c.created} by #{c.author}")
          new_count += 1
          nc = HysComment.new
          nc.text = c.text
          nc.author = c.author
          nc.modified_at = c.modified
          nc.created_at = c.created
          nc.bbcid = c.message_id
          t.hys_comments << nc
      end
      print " * #{new_count} new comments\n" if new_count > 0
			log_info("thread #{t.bbcid}: #{new_count} new comments added to database from rss")

      rss_ids.each do |cid|
        next unless censored_ids.include?(cid)
        print " * missing comment #{cid} reappeared!\n"
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
          print " * new missing comment #{cid}\n"
					log_info("thread #{t.bbcid}: new missing comment #{c.bbcid}, created at  #{c.created_at} by #{c.author}")
          c.censored = 0
          c.save
      end
			log_info("thread #{t.bbcid}: skipped #{skip_count} comments at end of maxed out rss feed (dated #{oldest_comment}), due to time granularity") if skip_count > 0
    end
  end
  
	desc "read new comments and check for censored ones"
  task :getnewcomments => :environment do
		get_new_comments(['created_at >= now() - INTERVAL 1 month'])
	end

	desc "check for censored comments on the very latest threads"
	task :get_short_comments => :environment do
		log_info("get_short_comments started")
		get_new_comments(['created_at >= now() - INTERVAL 2 day'])
	end
	
	desc "check for censored comments on the medium term threads"
	task :get_medium_comments => :environment do
		log_info("get_medium_comments started")
		get_new_comments(['created_at < now() - INTERVAL 2 day and created_at >= now() - INTERVAL 7 day'])
	end
	
	desc "check for censored comments on the long term threads"
	task :get_long_comments => :environment do
		log_info("get_long_comments started")
		get_new_comments(['created_at < now() - INTERVAL 7 day and created_at >= now() - INTERVAL 2 month'])
	end

  desc "find any new news articles"
  task :get_new_articles => :environment do
    rss = get_rss_entries "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml"
    rss += get_rss_entries "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk/rss.xml"
    rss.entries.each do |e|
      next if NewsArticle.find_by_guid(e.guid)
      puts "New news article '#{e.title}'"
      a = NewsArticle.new
      a.guid = e.guid
      a.published_at = Time.parse(e.pubDate.to_s)
      a.source = "bbc"
      a.title = e.title
      a.url = e[:link]
      a.save
    end
  end

  desc "Detect and archive news article contents"
  task :get_new_article_versions => :environment do
    puts "Finding articles..."
    now = Time.now
    NewsArticle.find(:all, :order => 'updated_at desc').each do |article|
      hours_old = ( (now - article.updated_at) / ( 60 * 60 ) ).to_i + 1
      tens = ((now.to_i % (60*60*24)) / 600 ) + 1
      next unless (((now.to_i % (60*60*24)) / 600 ) % hours_old) == 0
      log_info "processing '#{article.guid}' last updated #{hours_old} hours ago"
      page_data = zget(article.url)
      page = NewsPage::BbcNewsPage.new(page_data)
      page.url = article.url
      next if page.text_hash.nil? or page.text_hash == article.latest_text_hash
      log_info "new version found for '#{article.guid}'"
      nv = NewsArticleVersion.new
      nv.populate_from_page(page)
      article.versions << nv
    end
  end

end
