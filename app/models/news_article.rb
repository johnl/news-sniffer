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

# A NewsArticle represents an article that usually has one or many versions.
class NewsArticle < ActiveRecord::Base

  has_many :versions, :class_name => 'NewsArticleVersion', :dependent => :destroy, :autosave => true
  validates_length_of :title, :minimum => 5
  validates_presence_of :source # bbc, guardian, independent?
  validates_presence_of :guid, :parser
  validates_uniqueness_of :guid
  validates_length_of :guid, :maximum => 250
  validates_length_of :url, :minimum => 10, :maximum => 250

  attr_readonly :versions_count

  before_validation :set_initial_next_check_period, :unless => :next_check_after?

  scope :due_check, lambda { order('next_check_after asc').where(["check_period < ? AND next_check_after < ?", 40.days.to_i, Time.now.utc]) }

  # Retrieve the news page from the web, parse it and create a new
  # version if necessary, returning the saved NewsArticleVersion
  def update_from_source
    if parser
      page = eval("WebPageParser::#{parser}").new(:url => url)
    else
      page = WebPageParser::ParserFactory.parser_for(:url => url)
    end
    if page
      begin
        update_from_page(page)
      rescue StandardError => e
        reload
        set_next_check_period
        logger.error("article_id=#{id} source=#{source} retrieval error #{e.inspect} #{e.to_s} next_check_after=#{next_check_after}")
        save!
      end
    else
      logger.warn("article_id=#{id} source=#{source} status=unknown_parser parser=#{parser}")
    end
  end

  # Create a new version from the parsed html if it changed, returning
  # the saved NewsArticleVersion
  def update_from_page(page)
    if page.hash.nil? or page.hash == latest_text_hash
      # Content didn't change
      set_next_check_period
      logger.info("article_id=#{id} status=unchanged next_check_after=#{next_check_after}")
      save
      nil
    elsif count_versions_by_hash(page.hash) > 1
      set_next_check_period
      logger.warn("article_id=#{id} status=flipflopping next_check_after=#{next_check_after}")
      save
      nil
    else
      # Content changed!
      version = versions.build
      version.populate_from_page(page)
      begin
        self.with_lock('LOCK IN SHARE MODE') do
          self.title = page.title
          reset_next_check_period
          version.save! # explicitly saved to raise more useful validation exception
          save!
        end
      rescue ActiveRecord::RecordInvalid => e
        reload
        set_next_check_period
        logger.error("article_id=#{id} status=RecordInvalid error=#{e} next_check_after=#{next_check_after}")
        save!
        return nil
      rescue Mysql2::Error=> e
        # Back off retrying articles that db won't accept for somer reason
        # such as bad utf, too large data, etc. No point trying forever.
        set_next_check_period
        logger.error("article_id=#{id} status=Mysql2::Error error=#{e} next_check_after=#{next_check_after}")
        save!
        return nil
      rescue ActiveRecord::StatementInvalid => e
        # Back off retrying articles that db won't accept for somer reason
        # such as bad utf, too large data, etc. No point trying forever.
        set_next_check_period
        logger.error("article_id=#{id} status=StatementInvalid error=#{e}  next_check_after=#{next_check_after}")
        save!
        return nil
      end
      logger.info("article_id=#{id} status=new_version version_id=#{version.id}")
      version
    end
  end

  def latest_text_hash
    versions.order('version desc').select(:text_hash).first.try(:text_hash)
  end

  def count_versions_by_hash(count_hash)
    versions.where(:text_hash => count_hash).count
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
