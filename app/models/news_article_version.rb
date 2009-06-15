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
  
  validates_presence_of :version, :title, :text, :text_hash
  validates_presence_of :news_article
  
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
  
  def to_xapian_doc
    XapianFu::XapianDoc.new(:id => id, :title => title, :text => text)
  end
  
  def self.xapian_search(query)
    docs = xapian_db_ro.search(query)
    doc = { }
    docs.each { |d| doc_hash[d.id] = d }
    versions = find(doc_hash.keys)
    versions.sort_by do |v|
      doc_hash[v.id].weight
    end.reverse
  end

  def self.xapian_db_ro
    @xapian_db_ro ||= XapianFu::XapianDb.new(:dir => File.join(RAILS_ROOT, 'xapian/news_article_versions'))
  end
  
  def self.xapian_db
    @xapian_db ||= XapianFu::XapianDb.new(:dir => File.join(RAILS_ROOT, 'xapian/news_article_versions'),
                                        :create => true,
                                        :store => [:id])
  end
  
  def self.xapian_rebuild
    logger.info("starting xapian_rebuild for NewsArticleVersion")
    find_in_batches do |batch|
      xapian_db.transaction do
        bm = Benchmark.measure do
          batch.each { |nv| xapian_db << nv.to_xapian_doc }
        end        
        puts logger.info("#{batch.size} versions indexed in %.2f seconds (#{(batch.size/bm.total).round}/second)" % bm.total)
      end
    end
    xapian_db.flush
  end
  
  private
  
  def set_new_version
    self.version = news_article.versions_count
  end
  
end
