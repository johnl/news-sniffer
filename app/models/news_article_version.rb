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
    self.text_hash = page.hash
    self.title = page.title
    # self.created_at = page.date
    self.url = page.url
    self.text = page.content.join("\n")
  end

  # news source (via NewsArticle) for ferret indexing
  def source
    self.news_article.source
  end

  def <=>(b)
    if b.is_a? NewsArticleVersion
      self.id <=> b.id
    end
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
