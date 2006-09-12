class HysThread < ActiveRecord::Base
  attr_accessor :ccount
  has_many :hys_comments
  validates_uniqueness_of :bbcid
  validates_presence_of :title
  has_many :censored, :class_name => 'HysComment', :conditions => ['censored = 0']
  has_many :hardcensored, :class_name => 'HysComment', :conditions => ['censored = 0 and updated_at < (now() - INTERVAL 16 minute)']

  def comment_ids_since(time)
    hys_comments.find(:all, :conditions => ['modified_at >= ?', time]).collect { |c| c.bbcid }
  end
  
  def censored_comment_ids_since(time)
    hys_comments.find(:all, :conditions => ['censored = 0 and modified_at >= ?', time]).collect { |c| c.bbcid }
  end

  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?threadID=#{bbcid}"
  end
end
