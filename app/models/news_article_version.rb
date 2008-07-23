class NewsArticleVersion < ActiveRecord::Base
  belongs_to :news_article
  before_create :set_new_version
  after_create :update_latest_hash
  after_create :inc_counter
  before_destroy :dec_counter
  
  has_many :comments, :conditions => "linktype = 'NewsArticleVersion'",
    :foreign_key => 'link_id'
  
  @@ferret_index = nil
  
  after_update :ferret_update
  after_create :ferret_create
  after_destroy :ferret_delete

  module SearchResult
    attr_accessor :total_hits
    attr_accessor :time
  end
  
  # Execute a search on the ferret index and return matching collection objects
  def self.ferret_search(search_string, options = {}, activerecord_options = {})
    versions = {}
    options = { :limit => 10 }.merge(options)
    options[:page] = 1 unless options[:page]
    results = nil
    hits = nil
    time = nil
      time = Benchmark.measure do
        results = NewsArticleVersion.ferret_index.search( search_string,
          :limit => options[:limit], :sort => options[:sort],
          :offset => (options[:page].to_i-1) * options[:limit] )
        # Get the db ids from ferret index
        hits_ids = results.hits.collect { |h| NewsArticleVersion.ferret_index[h.doc][:id].to_i }
        # Setup the order field to ensure we get the records in hit order
        activerecord_options.merge!( { :order => "field(news_article_versions.id, #{hits_ids.join(',')})" } )
        # Get the db records 
        hits = NewsArticleVersion.find( hits_ids, activerecord_options)
      end
    logger.info "ferret search for #{search_string} completed in #{time}"
    hits.extend(SearchResult)
    hits.total_hits = results.total_hits
    hits.time = time.format('%r')
    return hits
  end
 
  
  # Return the Ferret index object for this class.  Initialise if necessary
  def self.ferret_index(options = {})
    return @@ferret_index unless @@ferret_index.nil?
    @@ferret_index = NsDrb::services[:news_article_version_ferret]
  end
  
  # Initialise ferret index for this class
  def self.ferret_init_index(options = {})
    @@ferret_index.close unless @@ferret_index.nil?
    options = { :create => false }.merge(options)
    field_infos = Index::FieldInfos.new(:term_vector => :no, :store => :no)
    field_infos.add_field(:id, :index => :untokenized, :store => :yes)
    field_infos.add_field(:created_at, :index => :untokenized )
    field_infos.add_field(:url, :index => :untokenized)
    field_infos.add_field(:text)
    field_infos.add_field(:title)
    field_infos.add_field(:source)
    @@ferret_index = Index::Index.new(:path => "#{RAILS_ROOT}/ferret_index/#{RAILS_ENV}/news_article_versions", 
      :field_infos => field_infos, 
      :default_input_field => :text,
      :create => options[:create],
      :all_fields => [:text, :title, :url],
      :or_default => false,
      :default_slow => 2)
    @@ferret_index
  end
  
  # Rebuild entire ferret index from database. Recreate index file if first parameter is true.
  def self.ferret_rebuild(recreate = false)
    logger.info("Rebuilding ferret index for news_article_versions")
    NewsArticleVersion.ferret_index(:create => recreate)
    offset = 0
    limit = 1000
    max = self.count
    until (offset > max) do
      logger.info("Indexing records #{offset} to #{offset + limit-1}...")
      self.benchmark("Indexing records #{offset} to #{offset + limit-1}") do
        self.find(:all, :limit => limit, :offset => offset).each { |t| t.ferret_create }
        offset += limit
      end
    end
    self.ferret_index.optimize
    return true
  end
  

  # Return a hash for this object suitable for adding to a ferret index
  def to_ferret_doc
    hash = {}
    NewsArticleVersion.ferret_index.field_infos.fields.each do |fieldname|
      next if fieldname == :content
      if fieldname == :created_at
        field = self.created_at.strftime("%Y%m%d")
      else
        field = eval("self.#{fieldname}")
      end
      field = field.join(' ') if field.is_a? Array
      hash[fieldname] = field.to_s unless field.nil?
    end
    hash[:id] = self.id
    hash
  end

  # Add newly created objects to the Ferret index
  def ferret_create
    NewsArticleVersion.ferret_index << self.to_ferret_doc
  end
  
  # Add/update this object to the Ferret index
  def ferret_update
    NewsArticleVersion.ferret_index.query_update("id:#{self.id}", self.to_ferret_doc)
  end

  # Delete this object from the Ferret index
  def ferret_delete
    NewsArticleVersion.ferret_index.delete(self.id.to_s)
  end
 
  # populate the object from a NewsPage object
  def populate_from_page(page)
      self.text_hash = page.text_hash
      self.title = page.title
      # self.created_at = page.date
      self.url = page.url
      self.text = page.content.join('<p>')
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
