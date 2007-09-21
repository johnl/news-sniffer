namespace "revisionista" do
  desc "find any new Revisionista news articles"
  task :get_new_articles => :environment do
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk_politics/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/health/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/middle_east/rss.xml"
    NewsArticle.create_from_rss "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/americas/rss.xml"
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,15065,12,00.xml" # World
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,15065,11,00.xml" # UK news
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,,19,00.xml" # Politics
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,,29,00.xml" # Environment
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,,19,00.xml" # Politics
    NewsArticle.create_from_rss "guardian", "http://www.guardian.co.uk/rssfeed/0,,29,00.xml" # Environment
    NewsArticle.create_from_rss "independent", "http://news.independent.co.uk/world/index.jsp?service=rss" # World
    NewsArticle.create_from_rss "independent", "http://news.independent.co.uk/uk/index.jsp?service=rss" # UK
  end

  desc "Detect and archive Revisionista news article contents"
  task :get_new_versions => :environment do
    puts "Finding articles..."
    now = Time.now
    NewsArticle.find(:all, :order => 'updated_at desc', 
        :conditions => "updated_at > now( ) - INTERVAL 40 DAY").each do |article|
      hours_old = ( (now - article.updated_at) / ( 60 * 60 ) ).to_i + 1
      tens = ((now.to_i % (60*60*24)) / 600 ) + 1
      next unless (((now.to_i % (60*60*24)) / 600 ) % hours_old) == 0
      log_info "news article: '#{article.guid}' last updated #{hours_old} hours ago"

      article.update_from_source
    end
  end

  desc "Rebuild entire revisionista ferret index"
  task :rebuild_index => :environment do
    NewsArticleVersion.transaction do 
      NewsArticleVersion.ferret_rebuild(true)
    end
  end
end
