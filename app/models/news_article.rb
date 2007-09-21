class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', 
    :order => 'version desc', :dependent => :destroy
  validates_length_of :title, :minimum => 5
  validates_presence_of :source
  validates_presence_of :guid
  validates_length_of :url, :minimum => 10
  validates_uniqueness_of :guid


  # Retrieve the news page from the web, parse it and create a new version if detected
  # returns the saved NewsArticleVersion
  def update_from_source
    if versions.count > 35
      NSLOG.warn "NewsArticle:skipping article id:#{id} because too many versions"
      return nil
    end
    page_data = HTTP::zget(url)
    page = page_parser.new(page_data)
    page.url = url
    return nil if page.text_hash.nil? or page.text_hash == latest_text_hash
    if source == "guardian" and versions.find_all_by_text_hash(page.text_hash).size > 0
      NSLOG.warn "NewsArticle:skipping flip-flopping Guardian news article, id:#{id}"
      return nil
    end
    NSLOG.info "NewsArticle:new version found for '#{guid}'"
    update_attribute(:latest_text_hash, page.text_hash)
    nv = NewsArticleVersion.new
    nv.populate_from_page(page)
    versions << nv
    nv
  end

  # Return the title of the latest version of this article
  def latest_title
    v = self.versions[-1]
    return v.title unless v.nil?
    return self.title
  end
    
  # Given a URL to an rss feed, and the source identifier, created any new NewsArticles
  def self.create_from_rss(source, url)
    rss = get_rss_entries(url)
    articles = rss.entries.collect do |e|
      guid = e.guid || e[:link]
      next if NewsArticle.find_by_guid(guid)
      a = NewsArticle.new
      a.guid = guid
      date = e.pubDate || e[:dc_date]
      a.published_at = Time.parse(date.to_s)
      a.source = source
      a.title = NewsPage::NewsPage.unhtml(e.title)
      a.url = e[:link]
      begin
        a.save!
        NSLOG.info "NewsArticle:new news article found: '#{e.title}'"
        next a
      rescue ActiveRecord::RecordInvalid
        NSLOG.info "NewsArticle:news article '#{a.title}' not created: #{a.errors.full_messages}"
        next nil
      end
    end
    articles.compact
  end

  private
 
  # retrieve and parse the given rss feed url and return an array of SimpleRSS entry items
  def self.get_rss_entries(url)
    rssdata = HTTP::zget(url)
    begin
      rss = SimpleRSS.parse(rssdata)
      entries = rss.entries
    rescue SimpleRSSError
      NSLOG.error "NewsArticle:get_rss_entires:RSS malformed: #{url}"
      entries = []
    end
    return entries
  end

  # Return the NewsPage parser for this news source
  def page_parser
    case source
      when "bbc"
        NewsPage::BbcNewsPage
      when "guardian"
        NewsPage::GuardianUkNewsPage
      when "independent"
        NewsPage::IndependentUkNewsPage
    end
  end
  
  protected
  
  def validate_on_create
      if url =~ /http:\/\/news.bbc.co.uk.*\/sport1\//
#        logger.info "INFO:NewsArticle:Skipping bbc sport news article: #{NewsPage::NewsPage.unhtml(url)}"
        errors.add :url, 'seems to be a bbc sport url'
      end
  end
end
