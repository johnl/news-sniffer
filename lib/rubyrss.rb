#
# RubyRSS
# Copyright (c) 2006 Sergey Tikhonov <st@dairon.net>
# Distributed under MIT License
#

require "simple-rss"
require "open-uri"
load "templates.rb"

class RubyRSS
  attr_accessor :title, :link, :desc, :date, :items
  attr_reader :filename
 
  class Item < self
    attr_accessor :title, :link, :desc, :date
    def initialize( title, link, desc, date )
      @title = title
      @link = link
      @desc = desc
      @date = date
    end
  end

  def initialize( filename )
    @filename = filename
    @title = ""
    @link = ""
    @date = Time.new
    @items = []
  end

  def parse( template_name = "default" )
    rss = SimpleRSS.parse open(@filename)

    @title = rss.channel.title
    @link = rss.channel.link
    @date = rss.channel.pubDate || rss.channel.lastBuildDate || rss.channel.modified || Time.now.gmtime
    rss.items.each { |item|
      d = item.pubDate || item.lastBuildDate || item.modified || Time.now.gmtime
      @items << Item.new( item.title, item.link, item.description, d )
    }

    html = $html_templates[ template_name ].strip
    item_html = ($1).strip if html =~ /#items-start(?::\d+)?(.+)#items-end/m

    num_items, desc_size = 10, 0
    num_items = ($1).to_i if html =~ /#items-start:(\d+)/
    desc_size = ($1).to_i if html =~ /#item-desc:(\d+)/

    html.gsub!( /#title/, title )
    html.gsub!( /#link/, link )
    html.gsub!( /#desc/, desc ) if desc
    html.gsub!( /#date/, date.to_s )
    items_html = ""
    items[0..num_items].each { |item|
      temp_html = item_html.dup
      temp_html.gsub!( /#item-title/, item.title )
      temp_html.gsub!( /#item-link/, item.link )
      d = item.desc
      if desc_size != 0
        d = CGI.unescapeHTML(d).gsub( /<([^>]+)>/, "" )
        d = d[ 0, desc_size ]
        d.gsub!( /(\s[^\s]*)$/, "&hellip;" )
      end
      temp_html.gsub!( /#item-desc(:\d+)?/, d )
      temp_html.gsub!( /#item-date/, item.date.strftime("%b %d %H:%M") )
      items_html << temp_html
    }
    html.gsub!( /#items-start(:\d+)?(.*)#items-end/m, items_html )
    html
  end

  def generate( template_name = "rss2.0" )
    rss = $rss_templates[ template_name ].strip
    item_rss = ($1).strip if rss =~ /#items-start(.+)#items-end/m
    
    rss.gsub!( /#title/, title )
    rss.gsub!( /#link/, link )
    rss.gsub!( /#desc/, desc )
    rss.gsub!( /#date/, date.to_s )
    items_rss = ""
    items.each { |item|
      temp_rss = item_rss.dup
      temp_rss.gsub!( /#item-title/, item.title )
      temp_rss.gsub!( /#item-link/, item.link )
      temp_rss.gsub!( /#item-desc/, CGI.escapeHTML(item.desc) )
      temp_rss.gsub!( /#item-date/, item.date.to_s )
      items_rss << temp_rss + "\n"
    }
    rss.gsub!( /#items-start\n(.*)#items-end\n/m, items_rss )
    rss
  end
end
