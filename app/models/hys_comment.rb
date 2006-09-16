class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
#  has_many :votes, :foreign_key => 'relation_id', :conditions => ["class = ?", self.class_name]
  validates_uniqueness_of :bbcid

  def self.uncensor(bbcid)
    self.update_all "censored = 1", "bbcid = #{bbcid}"
  end
  
  def self.censor(bbcid)
    self.update_all "censored = 0", "bbcid = #{bbcid}"
  end

  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?messageID=#{bbcid}##{bbcid}"
  end
end
