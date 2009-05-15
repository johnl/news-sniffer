 namespace "revisionista" do
  desc "find any new Revisionista news articles"
  task :get_new_articles => :environment do
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk_politics/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/health/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/middle_east/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/americas/rss.xml"
  end

  desc "Detect and archive Revisionista news article contents"
  task :get_new_versions => :environment do
   puts "Finding articles..."
     NewsArticle.recently_updated.each do |article|
      log_info "NewsArticle: '#{article.guid}' last updated #{article.updated_at}"
      article.update_from_source
    end
  end

  def log_info(msg)
  	time = Time.now.strftime("%a %d/%m/%y %H:%M:%S")
    msg = "#{time}: #{msg}"
  	ActiveRecord::Base.logger.info(msg)
    puts msg
  end
end
