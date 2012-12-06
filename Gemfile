source :rubygems

gem "rails", "3.1.8"
gem "mysql2"
gem 'will_paginate', '~> 3.0'
gem 'feed_parser', :git => "https://github.com/johnl/feed_parser.git", :ref => "fe4b7095"

# Make web-page-parser faster
platforms :ruby_18 do
  # Needs libonig-dev debian/ubuntu package
  gem "oniguruma", ">=1.1.0"
end

# web-page-parser requires Debian/Ubuntu package libonig-dev (on ruby1.8)
gem "web-page-parser", :git => "git://github.com/johnl/web-page-parser.git", :ref => "57c7b6246", :require => "web-page-parser"

gem "diff-lcs", "1.1.3", :require => "diff/lcs"

# Requires xapian library, best installed on Debian/Ubuntu with t
# package "libxapian-ruby1.8"
gem "xapian-fu", "1.3.2"

group :development do
  gem "rdoc"
  gem "sqlite3"
	gem "rspec-core"
	gem "rspec-rails"
end
