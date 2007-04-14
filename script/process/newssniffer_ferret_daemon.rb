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

ferrets = { :news_article_version_ferret => NewsArticleVersion.ferret_init_index() }
DRb.install_id_conv DRb::TimerIdConv.new

host = DRB_SERVICE[:host]
port = DRB_SERVICE[:port]
puts "Starting druby ferret service on #{host}:#{port}"
server = DRb::DRbServer.new("druby://#{host}:#{port}", ferrets, :verbose => true )
server.thread.join
