#!/usr/bin/ruby 
#
require File.dirname(__FILE__) + '/../config/environment'
require 'RRDtool'

start = Date.parse("20060701")
rrdfilename = RAILS_ROOT + "/rrd/newssniffer-hyscomments.rrd"
imgfilename = RAILS_ROOT + "/public/images/newssniffer-hyscomments.png"

rrd = RRDtool.new(rrdfilename)

if ARGV.include? "create"
  rrd.create( 86400, start.to_time.to_i, 
    [
      "DS:censored:GAUGE:86400:0:U", "RRA:AVERAGE:0.5:1:365", "RRA:AVERAGE:0.5:30:520",
      "DS:published:GAUGE:86400:0:U", "RRA:AVERAGE:0.5:1:365", "RRA:AVERAGE:0.5:30:520"
    ] )

  date = start
  while (date < Date.today) do
   censored = HysComment.ferret_index.search("created_at:#{date.strftime("%Y%m%d")} censored:0").total_hits
   published = HysComment.ferret_index.search("created_at:#{date.strftime("%Y%m%d")} censored:1").total_hits
   puts "#{date.strftime("%Y%m%d")}: #{censored} #{published}"
   rrd.update("censored:published", ["#{date.to_time.to_i}:#{censored}:#{published}"])
   date += 1
  end
end

if ARGV.include? "update"
  date = Date.today - 1
  censored = HysComment.ferret_index.search("created_at:#{date.strftime("%Y%m%d")} censored:0").total_hits
  published = HysComment.ferret_index.search("created_at:#{date.strftime("%Y%m%d")} censored:1").total_hits
  begin
    rrd.update("censored:published", ["#{date.to_time.to_i}:#{censored}:#{published}"])
  rescue RRDtoolError
  end

  RRDtool.graph( [imgfilename, 
    "DEF:pub=#{rrdfilename}:published:AVERAGE",
    "DEF:cen=#{rrdfilename}:censored:AVERAGE",
    "CDEF:ratio=cen,pub,cen,+,/,100,*",
    "--title", "News Sniffer BBC Have Your Say censored comments",
    "--start", start.to_time.to_i,
    "--end", (Date.today - 1).to_time.to_i,
    "--width=500",
#    "AREA:cen#ee7777:censored",
#   "AREA:pub#77ee77:published:STACK",
    "--upper-limit=10","-r",
    "AREA:ratio#7777ee:% proportion of comments censored daily"] )

end

