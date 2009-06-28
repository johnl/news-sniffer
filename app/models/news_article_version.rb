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
  belongs_to :news_article, :counter_cache => 'versions_count'
  before_validation :set_new_version
  attr_reader :text
  has_one :news_article_version_text, :dependent => :delete
  validates_presence_of :version, :title, :text, :text_hash
  validates_presence_of :news_article
  before_validation :setup_text
  after_save :update_text
 
  # populate the object from a NewsPage object
  def populate_from_page(page)
    self.text_hash = page.hash
    self.title = page.title
    # self.created_at = page.date
    self.url = page.url
    self.text = page.content.join("\n")
  end

  def <=>(b)
    if b.is_a? NewsArticleVersion
      self.id <=> b.id
    end
  end
  
  def text
    @text ||= news_article_version_text.to_s
  end
  
  def text=(new_text)
    @text_changed = true if @text != new_text
    @text = new_text
  end
  
  private
  
  def setup_text
    build_news_article_version_text unless news_article_version_text
    true
  end
  
  def update_text
    if @text_changed
      news_article_version_text.update_attributes(:text => @text)
    end
    true
  end
  
  def set_new_version
    self.version = news_article.versions_count
  end
  
end
