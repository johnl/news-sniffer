class HysComment < ActiveRecord::Base
  belongs_to :hys_thread
#  has_many :votes, :foreign_key => 'relation_id', :conditions => ["class = ?", self.class_name]
  validates_uniqueness_of :bbcid


  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?messageID=#{bbcid}##{bbcid}"
  end
end
