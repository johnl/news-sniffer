# BBCNews website parsing routines
# Copyright (C) 2006 John Leach - http://johnleach.co.uk

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module BBCNews
  require 'rubygems'
  require 'simple-rss'
  require 'open-uri'
  require 'net/http'
  require 'yaml'
  require 'erb'
  require 'time'

  class BBCNewsError < StandardError
  end
  class BadHaveYourSay < BBCNewsError
  end

  class Haveyoursaycomment
  
    attr_reader :text, :author, :created, :modified, :thread_id
    attr_accessor :deleted_at
        
    def self.find_from_rss(thread_id)
      rssdata = open("http://newsforums.bbc.co.uk/nol/rss/rssmessages.jspa?threadID=#{thread_id}&numItems=1000", "r").read
      begin
        rss = SimpleRSS.parse rssdata
      rescue SimpleRSSError
        return [[], 0]
      end
      [rss.entries.collect { |entry| self.instantiate_from_rss(entry, thread_id) }.uniq, rssdata.size]
    end
    
    def self.instantiate_from_rss(entry, thread_id)
      object = allocate
      object.populate_from_rss(entry, thread_id)
      object
    end  

    def populate_from_rss(entry, thread_id)
      begin
        @thread_id = thread_id
        @text = entry[:description]
        @link = entry[:link]
        @author = entry[:jf_author]
        @created = Time.parse( entry[:jf_creationDate].to_s )
        @modified = Time.parse( entry[:jf_modificationDate].to_s )
      rescue NameError
        raise BadHaveYourSay, "RSS entry didn't look right"
      end

    end
    
    def message_id
      return @message_id if @message_id
      return nil unless @link =~ /^.*messageID=([0-9]+).*$/
      @message_id = $1.to_i
      @message_id
    end
   
    def <=>(o)
      o.modified <=> @modified
    end
    
    def ==(o)
      o.message_id == message_id
    end
    
    def eql?(o)
      o.message_id == message_id
    end
    
    def hash
      message_id
    end
        
  end
    
  class Haveyoursay
    attr_reader :title, :link, :comments_updated, :published
    
    def comments
      begin
        @comments = YAML.load_file("comments-#{@thread_id}.yaml") unless @comments
      rescue Errno::ENOENT
        @comments = []
      end
      @comments || []
    end
    
    def missing_comments
      @missing_comments || []
    end
    
    # Remove reappeared comments from missing_comments list (caching problems?)
    def check_for_reappearance(rsslist)
      @missing_comments.delete_if { |c| rsslist.index(c) }
    end
    
    def add_missing_comments(list)
      @missing_comments = [] unless @missing_comments
      list.each do |c|
        unless @missing_comments.index(c)
          c.deleted_at = Time.now
          @missing_comments << c
        end
      end
    end
    
    # Return Haveyoursay objects for every page found cached on disk
    def self.find_from_disk
      l = Dir.glob("thread-*.yaml").collect { |filename| YAML.load_file(filename) }
      l.delete(false)
      l
    end
    
    # Return new Haveyoursay objects for every page found in the rss feed
    def self.find_from_rss
      rss = SimpleRSS.parse open("http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/talking_point/rss.xml", "r")
      rss.entries.collect { |entry| instantiate_from_rss(entry) }
    end
    
    def self.instantiate_from_rss(entry)
      object = allocate
      object.populate_from_rss entry
      object
    end
  
    # check to see if content-length is different from last time
    # we *should* use the date field, but bbc webserver is broken
    def rss_updated?
      # http://newsforums.bbc.co.uk/nol/rss/rssmessages.jspa?threadID=#{thread_id}&numItems=1000
      return true if @comments_updated.nil?
      response = nil
      begin
        Net::HTTP.start('newsforums.bbc.co.uk', 80) do |http|
          response = http.head("/nol/rss/rssmessages.jspa?threadID=#{thread_id}")
        end
      rescue Timeout::Error
        return false
      end
      return false unless response.to_hash.has_key? 'content-length'
      response['content-length'].to_i != @comments_rss_size
    end
    
    def thread_id
      return @thread_id if @thread_id
      return nil unless @link =~ /^.*threadID=([0-9]+).*$/
      @thread_id = $1.to_i
      @thread_id
    end

    def populate_from_rss(entry)
      begin
        @title = entry[:title]
        @published = Time.parse( entry[:pubDate].to_s )
        @link = entry[:link]
      rescue NameError
        raise BadHaveYourSay, "RSS entry didn't look right"
      end
    end
    
    # Save this objec to disk
    def save
      File.open( "comments-#{thread_id}.yaml", 'w' ) do |out|
       YAML.dump( @comments, out )
      end
      return unless @comments
      comments_backup = @comments
      @comments = nil
      File.open( "thread-#{thread_id}.yaml", 'w' ) do |out|
       YAML.dump( self, out )
      end
      @comments = comments_backup
      comments_backup = nil
    end
    
    # Is the thread closed?
    def closed?
      thread_id ? false : true
    end

    # get comments from rss feed   
    def rss_comments
      comments, content_length = Haveyoursaycomment.find_from_rss(thread_id)
      @comments_rss_size = content_length
      comments
    end

    # Add any new comments from list    
    def add_comments(list)
      @comments = [] if @comments.nil?    
      list.each { |c| @comments << c unless @comments.index(c) }
      @comments_updated = Time.now      
    end
    
    def ==(o)
      o.thread_id == thread_id if o.is_a? Haveyoursay
    end
    
    def <=>(o)
      o.published <=> @published if o.is_a? Haveyoursay
    end
    
  end
  
end

