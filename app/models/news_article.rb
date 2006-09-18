class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', 
    :order => 'version desc'

  def latest_title
    v = self.versions[-1]
    return v.title unless v.nil?
    return self.title
  end
end
