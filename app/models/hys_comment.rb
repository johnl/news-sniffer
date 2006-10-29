# The HysComment object represents a BBC Have Your Say comment, usually associated
# with a HysThread object.
class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
#  has_many :votes, :foreign_key => 'relation_id', :conditions => ["class = ?", self.class_name]
  validates_uniqueness_of :bbcid
  validates_associated :hys_thread

  # Mark the specified (by bbcid) comment as not censored and save
  def self.uncensor(bbcid)
    c = self.find_by_bbcid(bbcid, :include => :hys_thread)
    c.update_attribute(:censored, NOTCENSORED)
  end
  
  # Mark the specified (by bbcid) comment as censored and save
  def self.censor(bbcid)
    c = self.find_by_bbcid(bbcid, :include => :hys_thread)
    c.update_attribute(:censored, CENSORED)
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
      self.author = entry[:jf_author]
      self.created_at = Time.parse( entry[:jf_creationDate].to_s )
      self.modified_at = Time.parse( entry[:jf_modificationDate].to_s )
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
