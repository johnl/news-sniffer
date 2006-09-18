namespace "revisionista" do
  require 'open-uri'
  require 'simple-rss'
  require 'zget'
  require 'digest'
  require 'htmldiff'
  require 'news_page'
  include HTMLDiff
  include BBCNews
  require 'cgi'
  
  def unhtml(s)
    t = CGI::unescapeHTML(s)
    t = t.gsub(/&apos;/i, "'")
    t
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
    
  def get_new_articles(source, url)
    rss = get_rss_entries(url)
    rss.entries.each do |e|
      guid = e.guid || e[:link]
      next if NewsArticle.find_by_guid(guid)
      log_info "New news article found: '#{unhtml(e.title)}'"
      a = NewsArticle.new
      a.guid = guid
      date = e.pubDate || e[:dc_date]
      a.published_at = Time.parse(date.to_s)
      a.source = source
      a.title = unhtml(e.title)
      a.url = e[:link]
      a.save
    end
  end
    
  desc "find any new Revisionista news articles"
  task :get_new_articles => :environment do
    get_new_articles "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml"
    get_new_articles "bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk/rss.xml"
    get_new_articles "guardian", "http://www.guardian.co.uk/rssfeed/0,15065,12,00.xml" # World
    get_new_articles "guardian", "http://www.guardian.co.uk/rssfeed/0,15065,11,00.xml" # UK news
    get_new_articles "independent", "http://news.independent.co.uk/world/index.jsp?service=rss" # World
    get_new_articles "independent", "http://news.independent.co.uk/uk/index.jsp?service=rss" # UK
  end

  desc "Detect and archive Revisionista news article contents"
  task :get_new_versions => :environment do
    puts "Finding articles..."
    now = Time.now
    NewsArticle.find(:all, :order => 'updated_at desc').each do |article|
      unless ARGV.grep("all")
        hours_old = ( (now - article.updated_at) / ( 60 * 60 ) ).to_i + 1
        tens = ((now.to_i % (60*60*24)) / 600 ) + 1
        next unless (((now.to_i % (60*60*24)) / 600 ) % hours_old) == 0
      end
      log_info "news article: '#{article.guid}' last updated #{hours_old} hours ago"
      page_data = zget(article.url)
      case article.source
        when "bbc"
          page = NewsPage::BbcNewsPage.new(page_data)
        when "guardian"
          page = NewsPage::GuardianUkNewsPage.new(page_data)
        when "independent"
          page = NewsPage::IndependentUkNewsPage.new(page_data)
      end
      page.url = article.url
      next if page.text_hash.nil? or page.text_hash == article.latest_text_hash
      log_info "new version found for '#{article.guid}'"
      nv = NewsArticleVersion.new
      nv.populate_from_page(page)
      article.versions << nv
    end
  end
end
