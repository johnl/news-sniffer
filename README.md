# News Sniffer

News Sniffer monitors news websites and detects when articles
change. The versions are viewable and the changes are highlighted.

The main deployment is at http://www.newssniffer.co.uk/ which currently monitors
a key feeds from several news sources excluding a few sections like Sports (as
they change too often with just scores).

The code is available under a free software license, so anybody can
run their own deployment and monitor whatever news sources they wish
(or just contribute to development).

# The code

News Sniffer uses the Ruby on Rails web framework. This document
presumes you're familiar with that.

News Sniffer uses the `web-page-parser` ruby library to parse the text
out of the news article html pages.  If you want to add support for
other news sources, then start with adding it there:
https://github.com/johnl/web-page-parser

## Getting started

Check out the code, and install the gems:

    $ bundle install 

configure a local mysql or sqlite development
database and create the db and load the schema:

    $ bundle exec rake db:create
    $ bundle exec rake db:schema:load

Then, using the rails console, add your first rss news feed. Let's add
a BBC news feed:

    $ bundle exec rails console
    
    irb(main):001:0> NewsArticleFeed.create :name => "BBC News", :url => "http://feeds.bbci.co.uk/news/rss.xml", :source => "bbc", :check_period => 300

The `:source` option is an arbitrary key that is used to group several
feeds with the same source (and it's displayed on the article page).
The `:check_period` options is the number of seconds to wait between
re-downloading the feed to check for new articles.

Then run the `newssniffer:articles:update` rake task which will
download the feeds and create `NewsArticle` records for any articles
it finds:

    $ bundle exec rake newssniffer:articles:update
    newssniffer:articles:update
    NewsArticleFeed 1
    NewsArticleFeed 1, 79 new articles discovered

Then run the `newssniffer:versions:update` rake task, which will
download the page content for the news articles:

    $ bundle exec rake newssniffer:versions:update
    newssniffer:versions:update
    NewsArticle 1 new version found 1
    NewsArticle 2 new version found 2
    NewsArticle 3 new version found 3
	
You can run these rake tasks as often as you like - only the feeds and
articles that are overdue a check are processed.

## Filtering out articles

News Sniffer supports filtering rss feeds, so you can avoid tracking
certain articles.  Currently it supports filtering by regular
expressions applied to the urls (used by www.newssniffer.co.uk to
filter out certain articles from the BBC, such as sport articles which
change a lot and aren't usually interesting politically).

You specify filters by creating `NewsArticleFeed` records:

    $ NewsArticleFeedFilter.create :name => "Ignore BBC sport articles", :url_filter => 'sport/0'

# More Info

Author: John Leach (mailto:john@johnleach.co.uk)

Copyright: Copyright (c) 2006-2016 John Leach

License: GNU Affero General Public License v3

Web page: http://www.newssniffer.co.uk

Github: http://github.com/johnl/news-sniffer
