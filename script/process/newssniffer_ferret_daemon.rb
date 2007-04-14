#!/usr/bin/ruby

require File.dirname(__FILE__) + '/../../config/environment'

module Ferret::Index
  class Index
    alias :real_search :search
  
    def search(*args)
      r = nil
      b = Benchmark.measure { r = real_search(*args) }
      puts "ferret search completed in #{b.to_s}"
      return r
    end
    
  end
end

class ActionController::Caching::Fragments::FileStore
  include DRb::DRbUndumped
  def write(*args)
    puts "fragment write " + args.first
    super *args
  end
  def read(*args)
    puts "fragment read " + args.first
    super *args
  end
end


services = { 
  :news_article_version_ferret => NewsArticleVersion.ferret_init_index(),
  :fragment_cache => ActionController::Base.fragment_cache_store
  }
DRb.install_id_conv DRb::TimerIdConv.new

puts "Starting druby ferret service on #{NsDrb::url}"
server = DRb::DRbServer.new(NsDrb::url, services, :verbose => true )
server.thread.join
