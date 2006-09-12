class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', 
    :order => 'version desc'

#  def add_new_version(version)
#    self.versions << version
#    self.latest_text_hash = version.text_hash
#    self.versions_count += 1
#    self.save
#  end
end
