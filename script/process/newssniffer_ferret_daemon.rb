#!/usr/bin/ruby

require File.dirname(__FILE__) + '/../../config/environment'

module Ferret::Index
class Index
  alias :real_search :search

  def search(*args)
    r = nil
    b = Benchmark.measure do
      r = real_search(*args)
    end
    puts b
    r
  end
  
end
end

services = { 
  :news_article_version_ferret => NewsArticleVersion.ferret_init_index(),
  :fragment_cache => ActiveRecord::Base.allow_concurrency
  }
DRb.install_id_conv DRb::TimerIdConv.new

puts "Starting druby ferret service on #{NsDrb::url}"
server = DRb::DRbServer.new(NsDrb::url, services, :verbose => true )
server.thread.join
