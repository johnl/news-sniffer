# The HysComment object represents a BBC Have Your Say comment, usually associated
# with a HysThread object.
class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
#  has_many :votes, :foreign_key => 'relation_id', :conditions => ["class = ?", self.class_name]
  validates_uniqueness_of :bbcid

  # Mark the specified (by bbcid) comment as not censored and save
  def self.uncensor(bbcid)
    c = self.find_by_bbcid(bbcid, :include => :hys_thread)
    c.update_attribute(:censored, 1)
  end
  
  # Mark the specified (by bbcid) comment as censored and save
  def self.censor(bbcid)
    c = self.find_by_bbcid(bbcid, :include => :hys_thread)
    c.update_attribute(:censored, 0)
  end

  # Return the url for this comment on the bbc website
  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?messageID=#{bbcid}##{bbcid}"
  end

end
