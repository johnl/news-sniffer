#!/usr/bin/ruby

require File.dirname(__FILE__) + '/config/environment'

server = DRb::DRbServer.new("druby://127.0.0.1:9001", NewsArticleVersion.ferret_init_index(), :verbose => true )
server.thread.join
