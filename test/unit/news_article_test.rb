require File.dirname(__FILE__) + '/../test_helper'

class NewsArticleTest < Test::Unit::TestCase
  fixtures :news_articles, :news_article_versions

  # Replace this with your real tests.
  def test_create_from_rss
    articles = NewsArticle.create_from_rss('bbc', "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml")
    assert articles.size > 0, "no articles created"
    articles = NewsArticle.create_from_rss('bbc', "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml")
    assert_equal 0, articles.size, "duplicate articles created"
    articles = NewsArticle.create_from_rss('bbc', "http://newsrss.bbc.co.uk/rss/sportonline_uk_edition/cricket/rss.xml")
    assert articles.size < 5, "bbc news sport articles got created!"
  end

  def test_update_from_source
    a = news_articles(:lebanon)
    lhash = a.latest_text_hash
    assert_equal 2, a.versions.count
    v = a.update_from_source
    assert_not_nil v
    assert v.is_a?(NewsArticleVersion), "update_from_source didn't return a NewsArticleVersion"
    assert_equal 3, a.versions.count, "a new version wasn't created in the db"
    assert_equal 3, a.versions_count, "versions count field wasn't incremented"
    assert_not_equal lhash, a.latest_text_hash, "latest_text_hash wasn't updated"
    assert_equal a.latest_text_hash, v.text_hash, "latest_text_hash didn't match version text hash"
    v2 = a.update_from_source
    assert_nil v2, "new version created of duplicate content"
    assert_equal 3, a.versions.count, "new version created of duplicate content"
  end
end
