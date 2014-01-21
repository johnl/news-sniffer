class NewsArticleVersionText < ActiveRecord::Base
  self.primary_key = :news_article_version_id
  validates_presence_of :news_article_version_id

  def to_s
    self.text.to_s
  end
end
