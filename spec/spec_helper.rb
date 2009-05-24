# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'
require 'web-page-parser'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end

def a_news_article(options = { })
  @guid_count = @guid_count.to_i + 1
  NewsArticle.create! @valid_attributes.merge(:guid => @guid_count).merge(options)
end

def some_news_page_html
  @a_news_page ||= File.read("spec/fixtures/web_pages/7984711-A.stm.html")
end

def some_news_page_html_with_a_change
  @a_news_page_with_a_change ||= File.read("spec/fixtures/web_pages/7984711-B.stm.html")
end

def a_news_article_with_one_version
  na = a_news_article
  p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
  na.update_from_page(p)
  na.reload
end

def a_news_article_with_two_versions
  na = a_news_article
  p1 = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
  p2 = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html_with_a_change)
  na.update_from_page(p1)
  na.update_from_page(p2)
  na.reload
end

def some_rss_feed_xml
  @some_rss_feed_xml ||= File.read("spec/fixtures/rss_feeds/bbc_uk_politics.xml")
end
