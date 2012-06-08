#    News Sniffer
#    Copyright (C) 2007-2012 John Leach
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

class NewsArticleFeed < ActiveRecord::Base
  validates_presence_of :name, :url, :source
  validates_uniqueness_of :name, :url
  validates_numericality_of :check_period, :greater_than_or_equal_to => 300
  validates_presence_of :next_check_after
  before_validation :update_next_check_after, :unless => :next_check_after?
  
  scope :due_check, lambda { 
    {
      :conditions => ['next_check_after < ?', Time.now.utc]
    }
  }
  
  def update_next_check_after!
    update_next_check_after
    save!
  end
  
  def update_next_check_after
    if new_record?
      self.next_check_after = Time.now
    else  
      self.next_check_after = Time.now + check_period.to_i
    end
  end
  
  # Parse the feed and create any new NewsArticles
  def create_news_articles(rssdata = nil)
    rss = get_rss_entries(rssdata)
    entries = NewsArticleFeedFilter.filter(rss.entries)
    articles = entries.collect do |e|
      url = e[:link]
      page = WebPageParser::ParserFactory.parser_for(:url => url, :page => nil)
      next nil if page.nil?
      guid = e.guid || e[:link]
      next nil if NewsArticle.find_by_guid(guid)
      a = NewsArticle.new
      a.guid = guid
      date = e.pubDate || e[:dc_date]
      a.published_at = Time.parse(date.to_s) rescue Time.now
      a.source = source
      a.title = e.title
      a.url = url
      a.parser = page.class.to_s.split('::').last
      begin
        a.save!
        logger.debug "NewsArticleFeed #{id}, NewsArticle #{a.id} discovered"
        next a
      rescue ActiveRecord::RecordInvalid
        logger.error "NewsArticleFeed #{id}, NewsArticle '#{a.guid}' not created: #{a.errors.full_messages}"
        next nil
      end
    end
    articles = articles.compact
    logger.info "NewsArticleFeed #{id}, #{articles.size} new articles discovered"
    articles
  end
  
  # retrieve and parse the rss feed and return an array of SimpleRSS entry items
  def get_rss_entries(rssdata = nil)
    rssdata = HTTP::zget(url) unless rssdata
    entries = []
    begin
      rss = SimpleRSS.parse(rssdata)
      entries = rss.entries
    rescue SimpleRSSError => e
      logger.error "NewsArticleFeed #{id}, RSS Error: #{e}"
    end
    entries
  end

end
