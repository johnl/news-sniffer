class NewsArticleVersion < ActiveRecord::Base
  belongs_to :news_article
  before_create :set_new_version
  after_create :update_latest_hash
  after_create :inc_counter
  before_destroy :dec_counter
  
  has_many :comments, :conditions => "linktype = 'NewsArticleVersion'",
    :foreign_key => 'link_id'
 
  # populate the object from a NewsPage object
  def populate_from_page(page)
      self.text_hash = page.text_hash
      self.title = page.title
      # self.created_at = page.date
      self.url = page.url
      self.text = page.content.join('<p>')
  end
  
  private
  
  def set_new_version
    self.version = self.news_article.versions_count
  end
  
  def update_latest_hash
    self.news_article.update_attribute("latest_text_hash", self.text_hash)
  end
  
  def inc_counter
    NewsArticle.update_all 'versions_count = versions_count + 1', 
      "id = #{self.news_article.id}"
  end
  
  def dec_counter
    NewsArticle.update_all 'versions_count = versions_count - 1', 
      "id = #{self.news_article.id}"  
  end
end
