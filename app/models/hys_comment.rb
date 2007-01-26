# The HysComment object represents a BBC Have Your Say comment, always associated
# with a HysThread object.
class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
  validates_uniqueness_of :bbcid
  validates_associated :hys_thread

  # Mark the specified (by bbcid) comment as not censored and save
  def self.uncensor(bbcid)
    self.find_by_bbcid(bbcid, :include => :hys_thread).uncensor!
  end

  # Mark this comment as censored and save unless it's known as a thread_comment (see HysThread.thread_comment)
  def censor!
    return nil if self.author =~ /^nol-j.*/ # bbc admin usernames all begin with nol-j
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
      self.created_at = dc_date
      self.modified_at = self.created_at
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
