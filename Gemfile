source "https://rubygems.org"

gem "rails", "~> 4.1.0"
gem "mysql2"
gem 'will_paginate', '~> 3.0'
gem 'feed_parser', :git => "https://github.com/johnl/feed_parser.git", :ref => "fe4b7095"
gem 'lograge', '~> 0.3.1'

# Make web-page-parser faster
platforms :ruby_18 do
  # Needs libonig-dev debian/ubuntu package
  gem "oniguruma", ">=1.1.0"
end

# web-page-parser requires Debian/Ubuntu package libonig-dev (on ruby1.8)
gem "web-page-parser", :git => "git://github.com/johnl/web-page-parser.git", :ref => '4c7b22d', :require => "web-page-parser"

gem "diff-lcs", '~>1.2.5', :require => "diff/lcs"

# Requires xapian library
gem "xapian-fu", :git => "git://github.com/johnl/xapian-fu.git", :ref => 'index-field-name-options'
gem "xapian-ruby"

group :development do
  gem "rdoc"
  gem "sqlite3"
  gem "rspec-core"
  gem "rspec-rails"
  gem 'thin'
end

group "deployment" do
  gem "capistrano", "~>3.4"
  gem "capistrano-bundler"
end
