#    News Sniffer
#    Copyright (C) 2007-2008 John Leach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', 
    :order => 'version desc', :dependent => :destroy
  validates_length_of :title, :minimum => 5
  validates_presence_of :source # bbc, guardian, indepdent?
  validates_presence_of :guid
  validates_uniqueness_of :guid
  validates_length_of :url, :minimum => 10

  named_scope :recently_updated, :order => 'news_articles.updated_at desc', 
    :conditions => "news_articles.updated_at > now() - INTERVAL 40 DAY"

  # Retrieve the news page from the web, parse it and create a new
  # version if necessary, returning the saved NewsArticleVersion
  def update_from_source
    if versions.count > 35
      logger.warn "NewsArticle:skipping article id:#{id} because too many versions"
      return nil
    end
    page_data = HTTP::zget(url)
    update_from_page_data(page_data)
  end

  # Parse the given page html and create a new version if necessary,
  # returning the saved NewsArticleVersion
  def update_from_page_data(page_data)
    page = page_parser.new(page_data)
    page.url = url
    return nil if page.text_hash.nil? or page.text_hash == latest_text_hash
    nv = NewsArticleVersion.new
    nv.populate_from_page(page)
    transaction do
      update_attribute(:latest_text_hash, page.text_hash)
      versions << nv
    end
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
        logger.info "NewsArticle:new news article found: '#{e.title}'"
        next a
      rescue ActiveRecord::RecordInvalid
        logger.info "NewsArticle:news article '#{a.title}' not created: #{a.errors.full_messages}"
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
      logger.error "NewsArticle:get_rss_entires:RSS malformed: #{url}"
      entries = []
    end
    return entries
  end

  # Return the NewsPage parser for this news source
  def page_parser
    case source
      when "bbc"
        NewsPage::BbcNewsPage
    end
  end


  
  protected
  
  def validate_on_create
      # Quick hack to avoid bbc sport articles that crop up on various feeds and
      # are rarely interesting to us
      if url =~ /http:\/\/news.bbc.co.uk.*\/sport1\//
#        logger.info "INFO:NewsArticle:Skipping bbc sport news article: #{NewsPage::NewsPage.unhtml(url)}"
        errors.add :url, 'seems to be a bbc sport url'
      end
  end
end
