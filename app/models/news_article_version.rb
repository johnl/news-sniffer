
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
    self.text_hash = page.hash.to_s.force_encoding(Encoding::UTF_8)
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

  def to_xapian_doc
    XapianFu::XapianDoc.new(:id => id, :title => title, :text => text,
                            :news_article_id => news_article_id,
                            :created_at => created_at.to_date,
                            :version => version,
                            :source => news_article.source,
                            :url => url)
  end

  def text=(new_text)
    @text_changed = true if @text != new_text
    @text = new_text
  end

  def self.xapian_search(query, options = { })
    xapian_db.ro.reopen
    docs = xapian_db.search(query, options)
    docs.each_with_index do |d,i|
      begin
        docs[i] = find(d.id)
      rescue ActiveRecord::RecordNotFound
        # Handle documents deleted from db but not from Xapian
        docs[i] = nil
      end
    end
    docs.compact!
    docs
  end

  def self.xapian_db
    if @xapian_db
      @xapian_db
    else
      fields = {
        :created_at => { :type => Date, :store => true, :index => :with_field_names_only },
        :news_article_id => { :type => Fixnum, :store => true, :index => :with_field_names_only },
        :version => { :type => Fixnum, :index => :with_field_names_only },
        :source => { :type => String, :index => true },
        :url => { :type => String, :index => :with_field_names_only },
        :title => { :type => String },
        :text => { :type => String, :index => :without_field_names }
      }
      @xapian_db = XapianFu::XapianDb.new(:dir => xapian_db_path,
                                          :create => true, :fields => fields,
                                          :index_positions => true)
    end
  end

  private

  def self.xapian_db_path
    File.join(Rails.root, 'xapian/news_article_versions')
  end

  def setup_text
    build_news_article_version_text unless news_article_version_text
    true
  end

  def self.xapian_rebuild(options = { })
    s = NewsArticleVersion.where(options[:conditions]).includes(:news_article_version_text)
    s.find_in_batches(:batch_size => 1000) do |batch|
      xapian_batch_index(batch)
    end
  end

  def update_text
    if @text_changed
      news_article_version_text.update_attributes(:text => @text)
    end
    true
  end

  def self.xapian_batch_index(records)
    bm = Benchmark.measure do
      xapian_db.transaction do
        records.each { |nv| xapian_db << nv.to_xapian_doc }
      end
    end
    logger.info("task=xapian_batch_index versions=#{records.size} from=#{records.first.id} to=#{records.last.id}) time_to_index=%.2fs rate=#{(records.size/bm.total).round}/second)" % bm.total)
  end

  def self.xapian_update
    if last = xapian_db.documents.max(:id)
      logger.info("task=xapian_update last_news_article_versions_id=#{last.id}")
      xapian_rebuild(:conditions => ['news_article_versions.id > ?', last.id])
    else
      # No last id so rebuild the whole db
      xapian_rebuild
    end
  rescue Exception => e
    xapian_db.flush
    logger.error(e.to_s)
    raise e
  end

  def set_new_version
    self.version = news_article.versions_count if self.new_record?
  end

end
