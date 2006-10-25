# The HysThread model represents a BBC Have Your Say thread.
# The +++censored+++ relation returns all associated HysComments that were censored.
# The +++hardcensored+++ relation returns all associated HysComments that have remained censored for
# a period of time.
class HysThread < ActiveRecord::Base
  attr_accessor :ccount
  has_many :hys_comments
  validates_uniqueness_of :bbcid
  validates_presence_of :title
  has_many :censored, :class_name => 'HysComment', :conditions => ['censored = 0']
  has_many :hardcensored, :class_name => 'HysComment', :conditions => ['censored = 0 and hys_comments.updated_at < (now() - INTERVAL 16 minute)'], :include => 'hys_thread'

  # Return an array of ids of all HysComments from this 
  # thread modified since the time parameter
  def comment_ids_since(time)
    hys_comments.find(:all, :conditions => ['modified_at >= ?', time]).collect { |c| c.bbcid }
  end
  
  # Return an array of ids of censored HysComments from this
  # thread modified since the time parameter
  def censored_comment_ids_since(time)
    hys_comments.find(:all, :conditions => ['censored = 0 and modified_at >= ?', time]).collect { |c| c.bbcid }
  end

  # Return the url to the bbc website for this thread
  def url
    "http://newsforums.bbc.co.uk/nol/thread.jspa?threadID=#{bbcid}"
  end

end
