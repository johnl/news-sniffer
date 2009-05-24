#    News Sniffer
#    Copyright (C) 2007-2009 John Leach
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

# A NewsArticle represents an article that usually has one or many versions.
class NewsArticle < ActiveRecord::Base
  has_many :versions, :class_name => 'NewsArticleVersion', :dependent => :destroy, :autosave => true
  validates_length_of :title, :minimum => 5
  validates_presence_of :source # bbc, guardian, independent?
  validates_presence_of :guid, :parser
  validates_uniqueness_of :guid
  validates_length_of :url, :minimum => 10
  attr_readonly :versions_count

  before_validation :set_initial_next_check_period, :unless => :next_check_after?
    
  named_scope :due_check, lambda { 
    { 
      :order => 'next_check_after asc',
      :conditions => ["check_period < ? AND next_check_after < ?", 40.days.to_i, Time.now.utc],
    }
  }
  
  # Retrieve the news page from the web, parse it and create a new
  # version if necessary, returning the saved NewsArticleVersion
  def update_from_source
    page_data = HTTP::zget(url)
    if parser
      page = eval("WebPageParser::#{parser}").new(:url => url, :page => page_data)
    else
      page = WebPageParser::ParserFactory.parser_for(:url => url, :page => page_data)
    end
    if page
      update_from_page(page)
    else
      logger.warn("ParserFactory not created for NewsArticle #{id}")
    end
  end

  # Create a new version from the parsed html if it changed, returning
  # the saved NewsArticleVersion
  def update_from_page(page)
    if page.hash.nil? or page.hash == latest_text_hash
      # Content didn't change
      set_next_check_period
      logger.info("NewsArticle #{id} no changes, next_check_after: #{next_check_after}")
      save
      nil
    else
      # Content changed!
      version = versions.build
      version.populate_from_page(page)
      begin
        transaction do
          self.title = page.title
          self.latest_text_hash = page.hash
          self.last_version_at = Time.now
          reset_next_check_period
          version.save! # explicitly saved to raise more useful validation exception
          save!
        end
      rescue StandardError => e
        logger.error("NewsArticle #{id} error with new version: #{e.to_s}")
        raise e
      end
      logger.info("NewsArticle #{id} new version found #{version.id}")
      version
    end
  end


  private
 
  def set_next_check_period
    if check_period == 0
      self.check_period = 30.minutes 
    else
      self.check_period = (check_period * 1.2).round
    end
    self.next_check_after = Time.now + self.check_period
  end
  
  def reset_next_check_period
    self.check_period = 30.minutes
    self.next_check_after = Time.now + self.check_period
  end
  
  def set_initial_next_check_period
    self.check_period = 0
    self.next_check_after = Time.now
  end
end
