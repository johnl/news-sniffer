#    News Sniffer
#    Copyright (C) 2007-2016 John Leach
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

  scope :due_check, lambda { where(['next_check_after < ?', Time.now.utc]) }

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
      # make any guid that is a url into a https url
      https_guid = e[:guid].to_s.gsub('http:','https:')
      # guid is usually a better link than link, so try that first
      page = WebPageParser::ParserFactory.parser_for(:url => https_guid, :page => nil)
      # if using the guid wasn't possible or didn't work out, try link
      page = WebPageParser::ParserFactory.parser_for(:url => e[:link], :page => nil) if page.nil?
      # skip if still no luck
      next nil if page.nil?
      guid = page.guid || e[:guid] || page.url
      next nil if NewsArticle.find_by_guid(guid)
      a = NewsArticle.new
      a.guid = guid
      date = e[:pubDate] || e[:dc_date]
      a.published_at = Time.parse(date.to_s) rescue Time.now
      a.source = source
      a.title = e[:title]
      a.url = page.url
      a.parser = page.class.to_s.split('::').last
      begin
        a.save!
        logger.info "feed_id=#{id} news_article_id=#{a.id} status=new source=#{source}"
        next a
      rescue ActiveRecord::RecordInvalid
        logger.error "feed_id=#{id} news_article_guid='#{a.guid}' source=#{source} status=record_invalid errors=#{a.errors.full_messages}"
        next nil
      end
    end
    articles = articles.compact
    logger.info "feed_id=#{id} source=#{source} new_news_articles_count=#{articles.size}"
    articles
  end

  # retrieve and parse the rss feed and return an array of SimpleRSS entry items
  def get_rss_entries(rssdata = nil)
    @http_session ||= WebPageParser::HTTP::Session.new
    begin
      rssdata = @http_session.get(url) unless rssdata
    rescue StandardError => e
      logger.error "feed_id=#{id} source=#{source} error=#{e}"
      return []
    end

    entries = []
    begin
      fp = FeedParser.new(:feed_xml => rssdata)
      entries = fp.parse.items.collect { |i| i.as_json }
    rescue FeedParser::UnknownFeedType => e
      logger.error "feed_id=#{id} source=#{source} error=#{e}"
    end
    entries
  end

end
