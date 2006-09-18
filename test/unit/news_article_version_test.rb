require File.dirname(__FILE__) + '/../test_helper'

class NewsArticleVersionTest < Test::Unit::TestCase
  fixtures :news_article_versions, :news_articles

  # Replace this with your real tests.
  def test_create_version
    a = NewsArticle.find(1)
    v = NewsArticleVersion.new
    a.versions << v
    assert_equal 3, a.versions.count,
      "new version didn't get associated with article"
    a = NewsArticle.find(1)
    assert_equal 3, a.versions_count,
      "versions_cache didn't get updated"
    assert_equal 2, v.version, "doesn't get incremented version number on create"
  end
end
