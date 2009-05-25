# NewsArticleFeedFilter checks hashes, usually entries from NewsArticleFeeds, against
# predefined filters in the database.
class NewsArticleFeedFilter < ActiveRecord::Base
  include Oniguruma
  
  validates_presence_of :name
  
  validate :validate_url_filter, :if => :url_filter?
  
  # Takes a list of hashes and returns a list of only the allowed ones
  def filter(entries)
    entries.find_all { |e| allows?(e) }
  end
  
  # Takes a list of hashes and filters them against all known filters (or against the
  # provided list of filters)
  def self.filter(entries, filters = nil)
    filters = all unless filters
    filters.inject(entries) { |entries, f| f.filter(entries) }
  end
  
  # Takes a hash of an rss feed entry and checks it against the filters
  def allows?(entry)
    url_filter_allows?(entry[:url])
  end
    
  def url_filter_allows?(url)
    if url_filter
      return false if (@url_filter_re ||= ORegexp.new(url_filter)).match(url.to_s)
    end
    true
  end
  
  private

  def validate_url_filter
    regexp_valid?(:url_filter)
  end
  
  def regexp_valid?(attr)
    ORegexp.new(send(attr))
  rescue StandardError => e
    errors.add attr, "is not a valid regular expression: #{e}"
    nil
  end
  
end
