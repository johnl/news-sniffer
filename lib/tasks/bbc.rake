CENSORED = 0
NOTCENSORED = 1

namespace "bbc" do
  require 'open-uri'
  require 'simple-rss'
  require 'hys_thread'
  require 'hys_comment'

    
  def log_info(msg)
  	time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
  	ActiveRecord::Base.logger.info(msg)
    puts msg
  end
	
  def log_error(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
    ActiveRecord::Base.logger.error(msg)
    puts msg
  end
	
  def log_warn(msg)
    time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
    ActiveRecord::Base.logger.warn(msg)
    puts msg
  end

  desc "find any new BBC Hys threads"
  task :getnewthreads => :environment do
    HysThread.find_from_rss
  end

  def wymouth_check(find_conditions)
    HysThread.find(:all, :order => 'created_at desc', :conditions => find_conditions ).each do |t|
      ActiveRecord::Base.logger.debug("DEBUG:HysThread:#{t.bbcid}")
      html_ids = t.find_comments_ids_from_html
      if html_ids.nil?
        log_warn("WARN:wymouth_check found no comment ids from html for thread:#{t.bbcid}")
        next
      end

      # Check for comments mark censored that are actually published
      mis_censored_ids = html_ids - (html_ids - t.censored_comments_ids)
      #if (html_ids - t.censored_comments_ids).size != html_ids.size
      if mis_censored_ids.size > 0
        log_info("INFO:wymouth_check found #{mis_censored_ids.size} published comments marked censored on thread:#{t.bbcid}!")
        t.hys_comments.find_all_by_bbcid(mis_censored_ids).each { |c| c.uncensor! }
      end

      # Check for comments not mark censored that *are* actually censored
      mis_published_ids = (t.comments_ids - html_ids) - t.censored_comments_ids
      if mis_published_ids.size > 0
        log_info("INFO:wymouth_check found #{mis_published_ids.size} censored comments marked published on thread:#{t.bbcid}!")
        t.hys_comments.find_all_by_bbcid(mis_published_ids).each { |c| c.censor! }
      end
    end
  end

  # Read the RSS feed, create any new comments and mark any censored as censored
	def wymouth(find_conditions)
    # FIXME: this should be condition on updated_at, once the data is sorted out
    HysThread.find(:all, :order => 'created_at desc', :conditions => find_conditions ).each do |t|
      ActiveRecord::Base.logger.debug("DEBUG:hysthread:#{t.bbcid}")
      rsscomments = t.find_comments_from_rss
      if rsscomments.nil?
        ActiveRecord::Base.logger.debug("DEBUG:hysthread:#{t.bbcid} t.find_comments_from_rss returned nil")
        next 
      end
      rsscomments_ids = rsscomments.collect { |c| c.bbcid }

			log_info("INFO:hysthread:#{t.bbcid}: #{rsscomments.size} comments in rss, oldest:#{t.oldest_rss_comment}, #{t.hys_comments.count} in database")
      next if rsscomments.size == 0

      # Find any censored comments that reappeared and uncensor them
      reappeared = HysComment.find_all_by_bbcid_and_censored(rsscomments_ids, CENSORED)
      reappeared.each do |c|
				log_info("INFO:hysthread:#{t.bbcid}: missing comment:#{c.bbcid} reappeared, created at #{c.created_at} by #{c.author}")
        c.uncensor!
      end  

      # Detect any missing comments!
      conds = ["bbcid NOT IN (#{rsscomments_ids.join(',')}) AND censored = #{NOTCENSORED}"]
      if rsscomments_ids.size >= 200
        # due to the 1 second granularity, we can't regard missing comments with the same timestamp
        # as the oldest_rss_comment as actually missing, if the rss feed is maxed out
        conds[0] += " AND modified_at > ?"
        conds << t.oldest_rss_comment
      end
      missing = t.hys_comments.find(:all, :conditions => conds)
      missing.each do |c|
  			log_info("INFO:hysthread:#{t.bbcid}: new missing comment:#{c.bbcid}, created at #{c.created_at} by #{c.author}") if c.censor!
      end
    end # HysThread.find loop
  end
  
	desc "read new HYS comments and check for censored ones"
  task :getnewcomments => :environment do
	  wymouth(['created_at >= now() - INTERVAL 1 month'])
	end

	desc "check for censored HYS comments on the very latest threads"
	task :short_mouth => :environment do
		log_info("get_short_comments started")
		wymouth(['created_at >= now() - INTERVAL 2 day'])
	end
	
	desc "check for censored HYS comments on the medium term threads"
	task :medium_mouth => :environment do
		log_info("get_medium_comments started")
		wymouth(['created_at < now() - INTERVAL 2 day and created_at >= now() - INTERVAL 7 day'])
	end
	
	desc "check for censored HYS comments on the long term threads"
	task :long_mouth => :environment do
		log_info("get_long_comments started")
		wymouth(['created_at < now() - INTERVAL 7 day and created_at >= now() - INTERVAL 2 month'])
	end
  
  desc "validate censored comments against results from html scraping"
  task :html_short => :environment do
    log_info("check_against_html started")
    wymouth_check(['created_at >= now() - INTERVAL 2 day'])
  end

  desc "validate censored comments against results from html scraping"
  task :html_medium => :environment do
    log_info("check_against_html started")
    wymouth_check(['created_at < now() - INTERVAL 2 day and created_at >= now() - INTERVAL 7 day'])
  end
  
  desc "validate censored comments against results from html scraping"
  task :html_long => :environment do
    log_info("check_against_html started")
    wymouth_check(['created_at < now() - INTERVAL 7 day and created_at >= now() - INTERVAL 2 month'])
  end
  
  desc "validate censored comments against results from html scraping"
  task :html_all => :environment do
    log_info("check_against_html started")
    wymouth_check('1=1')
  end

end
