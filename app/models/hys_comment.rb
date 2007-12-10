# The HysComment object represents a BBC Have Your Say comment, always associated
# with a HysThread object.
class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
  validates_uniqueness_of :bbcid
  validates_associated :hys_thread
  
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
    total_hits = nil
    time = nil
      time = Benchmark.measure do
        results = HysComment.ferret_index.search( search_string,
          :limit => options[:limit], :sort => options[:sort],
          :offset => (options[:page].to_i-1) * options[:limit] )
        total_hits = results.total_hits
        # Get the db ids from ferret index
        hits_ids = results.hits.collect { |h| HysComment.ferret_index[h.doc][:id].to_i }
        # Setup the order field to ensure we get the records in hit order
        activerecord_options.merge!( { :order => "field(hys_comments.id, #{hits_ids.join(',')})" } )
        # Get the db records 
        hits = HysComment.find( hits_ids, activerecord_options)
      end
    logger.info "ferret search for #{search_string} completed in #{time}"
    hits.extend(SearchResult)
    hits.total_hits = total_hits
    hits.time = time.format('%r')
    return hits
  end
 
  
  # Return the Ferret index object for this class.  Initialise if necessary
  def self.ferret_index(options = {})
    return @@ferret_index unless @@ferret_index.nil?
    @@ferret_index = NsDrb::services[:hys_comment_ferret]
  end

  def self.ferret_server
    DRb.start_service("druby://127.0.0.1:9001", HysComment.ferret_init_index() )
    DRb.thread.join
  end
  
  # Initialise ferret index for this class
  def self.ferret_init_index(options = {})
    @@ferret_index.close unless @@ferret_index.nil?
    options = { :create => false }.merge(options)
    field_infos = Index::FieldInfos.new(:term_vector => :no, :store => :no)
    field_infos.add_field(:id, :index => :untokenized, :store => :yes)
    field_infos.add_field(:created_at, :index => :untokenized )
    field_infos.add_field(:text)
    field_infos.add_field(:censored, :index => :untokenized)
    field_infos.add_field(:author)
    field_infos.add_field(:bbcid, :index => :untokenized)
    @@ferret_index = Index::Index.new(:path => "#{RAILS_ROOT}/ferret_index/#{RAILS_ENV}/hys_comments", 
      :field_infos => field_infos, 
      :default_input_field => :text,
      :create => options[:create],
      :default_field => [:text, :author, :bbcid],
      :or_default => false,
      :default_slop => 2)
    @@ferret_index
  end
  
  # Rebuild entire ferret index from database. Recreate index file if first parameter is true.
  def self.ferret_rebuild(recreate = false)
    logger.info("Rebuilding ferret index for hys_comments")
    HysComment.ferret_index(:create => recreate)
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
    HysComment.ferret_index.field_infos.fields.each do |fieldname|
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

  def ferret_query_update(theid, hash)
    HysComment.ferret_index.query_update("id:#{theid}", hash)
  end

  def ferret_create
    HysComment.ferret_index << self.to_ferret_doc
  end
  
  # Add/update this object to the Ferret index
  def ferret_update
    ferret_query_update(self.id, self.to_ferret_doc)
  end

  # Delete this object from the Ferret index
  def ferret_delete
    HysComment.ferret_index.delete(self.id.to_s)
  end

  # Mark the specified (by bbcid) comment as not censored and save
  def self.uncensor(bbcid)
    self.find_by_bbcid(bbcid, :include => :hys_thread).uncensor!
  end

  # Mark this comment as censored and save unless it's known as a thread_comment (see HysThread.thread_comment)
  def censor!
    return nil if self.author =~ /^nol-j.*/ # bbc admin usernames all begin with nol-j
    return nil if self.author == "BBC Host"
    self.update_attribute(:censored, CENSORED) unless self.hys_thread.thread_comment and self.bbcid == self.hys_thread.thread_comment.bbcid
  end
  
  # Mark the specified (by bbcid) comment as censored and save
  def self.censor(bbcid)
    self.find_by_bbcid(bbcid, :include => :hys_thread).censor!
  end
  
  # Mark this comment as not censored and save
  def uncensor!
    self.update_attribute(:censored, NOTCENSORED)
  end

  # Return the url for this comment on the bbc website
  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?messageID=#{bbcid}##{bbcid}"
  end
  
  # Return a new HysComment initialized from the rss hash and HysThread.id
  def self.instantiate_from_rss(entry, hys_thread_id)
    object = self.new
    return object if object.populate_from_rss(entry, hys_thread_id)
    return nil
  end  

  # Returns nil if no row with bbcid exists in database
  def self.bbcid_exists?(bbcid)
    self.connection.execute("select bbcid from hys_comments where bbcid = #{bbcid.to_i}").fetch_row
  end

  # Setup attributes from RSS entry hash and HysThread.id and return self.  return nil on NameError
  def populate_from_rss(entry, hys_thread_id)
    begin
      self.hys_thread_id = hys_thread_id.to_i
      self.text = entry[:description]
      @rsslink = entry[:link]
      self.bbcid = $1.to_i if @rsslink =~ /^.*messageID=([0-9]+).*$/
      if self.bbcid.nil? # no bbcid, no service!
        logger.warn("HysComment.populate_from_rss got a nil bbcid: #{@rsslink}")
        return nil 
      end
      self.author = entry[:dc_creator]
      # BBC feeds have timestamps in the 24th hour for some innane reason
      dc_date = entry[:dc_date]
      if dc_date.class != Time
        logger.warn("WARN:HysComment.populate_from_rss got an unparsed timestamp on comment:#{self.bbcid} - trying hour 24 workaround")
        begin
          dc_date = Time.parse(dc_date.gsub('T24', 'T00'))
        rescue ArgumentError
          logger.error("ERROR:HysComment.populate_from_rss got an unparsable timestamp on comment:#{self.bbcid} - '#{entry[:dc_date]}'")
          return nil
        end
      end
      self.created_at = dc_date.utc
      self.modified_at = self.created_at.utc
      return true
    rescue NameError => e
      logger.debug("HysComment.populate_from_rss NameError exception: #{e.to_s}")
      return nil
    end
  end

  def <=>(other)
    self.bbcid <=> other.bbcid
  end
  
  def ==(other)
    self.bbcid == other.bbcid
  end


end
