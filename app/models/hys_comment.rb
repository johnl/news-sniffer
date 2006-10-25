# The HysComment object represents a BBC Have Your Say comment, usually associated
# with a HysThread object.
class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
#  has_many :votes, :foreign_key => 'relation_id', :conditions => ["class = ?", self.class_name]
  validates_uniqueness_of :bbcid

  # Mark the specified (by bbcid) comment as not censored in the database
  def self.uncensor(bbcid)
    self.update_all "censored = 1", "bbcid = #{bbcid}"
  end
  
  # Mark the specified (by bbcid) comment as censored in the database 
  def self.censor(bbcid)
    self.update_all "censored = 0", "bbcid = #{bbcid}"
  end

  # Return the url for this comment on the bbc website
  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?messageID=#{bbcid}##{bbcid}"
  end
end
