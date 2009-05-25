class NewsArticleFeedFilter < ActiveRecord::Base
  include Oniguruma
  
  validates_presence_of :name
  
  def allows?(entry)
    url_filter_allows?(entry[:url])
  end
    
  def url_filter_allows?(url)
    if url_filter
      return false if (@url_filter_re ||= ORegexp.new(url_filter)).match(url.to_s)
    end
    true
  end
end
