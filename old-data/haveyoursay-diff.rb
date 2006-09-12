# BBCNews 'Have your say' comment censoring detector
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

require 'bbcnews'
include BBCNews

require 'rubygems'
require 'feed_tools'

# Where to write out html
HTML_PATH = '/home/john/johnleach.co.uk/bbcnews/'

DEBUG = false

print "Loading pages from disk...\n"
@pages = Haveyoursay.find_from_disk

print "Finding new pages from rss...\n"
Haveyoursay.find_from_rss.each do |p|
  next if p.closed?
  unless @pages.index(p)
    print "New: #{p.title}, id #{p.thread_id}\n"
    p.save    
    @pages << p
  end
end

BASE_URL = "http://newworldodour.co.uk/watchyourmouth/"

print "Finding comments from rss...\n"

listpage_template = ERB.new( File.open('commentslist.rhtml').read, 0, "%<>")
  
@pages.sort.each do |@page|
  print "thread_id:#{@page.thread_id} title:'#{@page.title}'\n"
  unless @page.rss_updated?
    print " - RSS not changed since last update\n"
    next
  end
  @rsscomments = @page.rss_comments
  print " - #{@rsscomments.size} comments from feed\n" if DEBUG
  @newcomments = @rsscomments - @page.comments
  print " - #{@newcomments.size} new comments found\n" if DEBUG
  @missing = @page.comments - @rsscomments
  
  # remove any missing comments that just rolled off the bottom of the feed
  print " - ignoring missing comments older than #{@rsscomments.last.modified}\n" if DEBUG
  print " - missing comments before ignoring: #{@missing.size} " if DEBUG
  @missing.delete_if { |c| c.modified <= @rsscomments.last.modified }
  print "and after: #{@missing.size}\n" if DEBUG
  @page.add_missing_comments @missing
  @page.add_comments @newcomments

  @page.check_for_reappearance(@rsscomments)
  print " - new missing comments: #{@missing.size}\n" if DEBUG
  print " - writing html page\n"
  
  File.open(HTML_PATH + "haveyoursay-#{@page.thread_id}.html", "w") do |f|
    f.write listpage_template.result
  end
end

# If nothing changed, don't bother writing index or saving pages to disk
exit if @rsscomments.nil?

print "Writing index html page...\n"
indexpage_template = ERB.new( File.open('index.rhtml').read, 0, "%<>")
File.open(HTML_PATH + "index.html", "w") do |f|
  f.write indexpage_template.result
end

print "Writing rss page...\n"
@feed = FeedTools::Feed.new
@feed.title = "BBC News 'Have your say' censored comments'"
@feed.link = BASE_URL + "feed.rss"
@missing = []
@pages.each { |@p| @missing += @p.missing_comments.collect { |c| [c, @p.title] } }
@missing.sort.each do |c,title|
  i = FeedTools::FeedItem.new
  i.title = "Have your say: '#{title}' comment #{c.message_id}"
  i.author = c.author
  i.link = BASE_URL + "haveyoursay-#{c.thread_id}.html##{c.message_id}"
  i.id = i.link  
  i.published = c.created
  i.updated = c.deleted_at
  i.content = c.text
  @feed.entries << i
end

File.open(HTML_PATH + "comments.rss", "w") do |f|
  f.write @feed.build_xml("rss", 2.0 )
end
File.open(HTML_PATH + "comments.xml", "w") do |f|
  f.write @feed.build_xml("atom", 1.0 )
end

print "Saving data to disk...\n"
@pages.each do |p|
  p.save
end
