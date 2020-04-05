# Methods to handle defining and maintaining the xapian full text index
module NewsArticleVersion::XapianIndexing
  def self.included(base)
    base.extend ClassMethods
  end

  def to_xapian_doc
    html = Nokogiri::HTML.parse(text)
    XapianFu::XapianDoc.new(id: id, title: title, text: html.text,
                            news_article_id: news_article_id,
                            created_at: created_at.to_date, version: version,
                            source: news_article.source)
  end

  module ClassMethods
    def xapian_search(query, options = { })
      options.merge!({ collapse: :news_article_id })
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
        version: { type: Integer, index: :with_field_names_only },
        news_article_id: { type: Integer, store: true, index: false },
        source: { type: String, index: true },
        title: { type: String },
        text: { type: String, index: :without_field_names }
      }
      @xapian_db = XapianFu::XapianDb.new(dir: xapian_db_path, create: true, stopper_strategy: :all,
                                          fields: fields, index_positions: false, spelling: false,
                                          stemmer: false,
                                          additional_flag: Xapian::DB_NO_SYNC)
    end

    def xapian_db_path=(path)
      @xapian_db_path = path
    end

    def xapian_db_path
      @xapian_db_path ||= File.join(Rails.root, 'xapian/news_article_versions')
    end

    def xapian_rebuild(options = {})
      s = NewsArticleVersion.where(options[:conditions]).where(['version < 10']).includes(:news_article_version_text)
      max_batches = options[:max_batches] || 20
      total = 0
      batch_number = 0
      s.find_in_batches(batch_size: options[:batch_size] || 1000) do |batch|
        batch_number += 1
        xapian_batch_index(batch)
        total += batch.size
        break if batch_number == max_batches
      end
      total
    end

    def xapian_batch_index(records)
      bm = Benchmark.measure do
        xapian_db.transaction do
          records.each do |nv|
            logger.debug("task=xapian_batch_index version=#{nv.id}")
            xapian_db << nv.to_xapian_doc
          end
        end
      end
      logger.info("task=xapian_batch_index versions=#{records.size} from=#{records.first.id} to=#{records.last.id}) time_to_index=%.2fs rate=#{(records.size/bm.total).round}/s)" % bm.total)
    end

    def xapian_update(options = {})
      batch_size = options[:batch_size]
      max_batches = options[:max_batches]
      begin
        last = xapian_db.documents.max(:id)
      rescue IOError
        last = nil
      end
      if last
        logger.info("task=xapian_update last_news_article_versions_id=#{last.id}")
        total = xapian_rebuild(conditions: ['news_article_versions.id > ?', last.id],
                               batch_size: batch_size,
                               max_batches: max_batches)
      else
        # No last id so rebuild the whole db
        total = xapian_rebuild(batch_size: batch_size, max_batches: max_batches)
      end
      xapian_db.flush
      total
    rescue Exception => e
      logger.fatal(e.to_s)
      raise e
    end
  end
end
