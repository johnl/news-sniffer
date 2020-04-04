source "https://rubygems.org"

gem "rails", "~> 4.2.0"
gem 'responders', '~> 2.0'
gem 'sass-rails', '~> 5.0'
gem "mysql2"
gem 'will_paginate', '~> 3.0'
gem 'feed_parser', :git => "https://github.com/johnl/feed_parser.git", :ref => "fe4b7095"
gem 'lograge'

# web-page-parser requires Debian/Ubuntu package libonig-dev (on ruby1.8)
gem "web-page-parser", :git => "https://github.com/johnl/web-page-parser.git", :ref => 'release-1.3.0', :require => "web-page-parser"

gem "diff-lcs", '~>1.2.5', :require => "diff/lcs"

# Requires xapian library
#gem "xapian-fu", :git => "https://github.com/johnl/xapian-fu.git", :ref => 'additional-flags'
gem "xapian-fu", "~> 1.7.0"
gem "xapian-ruby"

gem "nokogiri"

gem "puma"

group :development do
  gem "rdoc"
  gem "sqlite3", "~> 1.3.13"
  gem "rspec-core"
  gem "rspec-rails"
  gem "ruby-prof"
end
