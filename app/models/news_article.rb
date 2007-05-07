class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', 
    :order => 'version desc', :dependent => :destroy
  validates_length_of :title, :minimum => 5
  validates_presence_of :source
  validates_presence_of :guid
  validates_length_of :url, :minimum => 10
  validates_uniqueness_of :guid

  def update_from_source
    page_data = HTTP::zget(url)
    page = page_parser.new(page_data)
    page.url = url
    return nil if page.text_hash.nil? or page.text_hash == latest_text_hash
    if source == "guardian" and versions.find_all_by_text_hash(page.text_hash).size > 0
      logger.warn "skipping flip-flopping Guardian news article, id:#{id}"
      return nil
    end
    logger.info("NewsArticle:new version found for '#{guid}'")
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
        logger.info "INFO:NewsArticle:new news article found: '#{e.title}'"
        next a
      rescue ActiveRecord::RecordInvalid
        logger.info "INFO:NewsArticle:news article '#{a.title}' not created: #{a.errors.full_messages}"
        next nil
      end
    end
    articles.compact
  end

  private
  
  def self.get_rss_entries(url)
    rssdata = HTTP::zget(url)
    begin
      rss = SimpleRSS.parse(rssdata)
      entries = rss.entries
    rescue SimpleRSSError
      logger.error("NewsArticle:get_rss_entires:RSS malformed: #{url}")
      entries = []
    end
    return entries
  end

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
