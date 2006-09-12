#!/usr/bin/ruby
require File.dirname(__FILE__) + "/../config/environment"
require "app/models/hys_thread"
require "app/models/hys_comment"

require 'bbcnews'
include BBCNews

FileUtils.chdir File.dirname(__FILE__)

@threads = Haveyoursay.find_from_disk
@threads.each do |ot|
  print "#{ot.thread_id} with #{ot.missing_comments.size} missing comments\n"
  nt =  HysThread.new
  nt.title = ot.title
  nt.bbcid = ot.thread_id
  nt.created_at = ot.published
  nt.save
  (ot.comments + ot.missing_comments).each do |oc|
    nc = HysComment.new
    nc.bbcid = oc.message_id
    nc.text = oc.text
    nc.author = oc.author
    nc.created_at = oc.created
    nc.modified_at = oc.modified
    nc.censored = 0 if ot.missing_comments.include?(oc)
    nt.hys_comments << nc
  end
end
  
