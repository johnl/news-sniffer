# Methods to handle defining and maintaining the xapian full text index
module NewsArticleVersion::XapianIndexing
  def self.included(base)
    base.extend ClassMethods
  end

  def to_xapian_doc
    XapianFu::XapianDoc.new(id: id, title: title, text: text, news_article_id: news_article_id,
                            created_at: created_at.to_date, version: version,
                            source: news_article.source, url: url)
  end

  module ClassMethods
    def xapian_search(query, options = { })
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

    def xapian_db
      return @xapian_db if @xapian_db
      fields = {
        created_at: { type: Date, store: true, index: :with_field_names_only },
        news_article_id: { type: Fixnum, store: true, index: :with_field_names_only },
        version: { type: Fixnum, index: :with_field_names_only },
        source: { type: String, index: true },
        url: { type: String, index: :with_field_names_only },
        title: { type: String },
        text: { type: String, index: :without_field_names }
      }
      @xapian_db = XapianFu::XapianDb.new(dir: xapian_db_path, create: true,
                                          fields: fields, index_positions: false)
    end

    def xapian_db_path
      File.join(Rails.root, 'xapian/news_article_versions')
    end

    def xapian_rebuild(options = {})
      s = NewsArticleVersion.where(options[:conditions]).includes(:news_article_version_text)
      s.find_in_batches(batch_size: 1000) do |batch|
        xapian_batch_index(batch)
      end
    end

    def xapian_batch_index(records)
      bm = Benchmark.measure do
        xapian_db.transaction do
          records.each { |nv| xapian_db << nv.to_xapian_doc }
        end
      end
      logger.info("task=xapian_batch_index versions=#{records.size} from=#{records.first.id} to=#{records.last.id}) time_to_index=%.2fs rate=#{(records.size/bm.total).round}/s)" % bm.total)
    end

    def xapian_update
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
  end
end
