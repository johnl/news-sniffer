require File.dirname(__FILE__) + '/../test_helper'

class VoteTest < Test::Unit::TestCase
  fixtures :news_articles
  fixtures :news_article_versions
  fixtures :votes

  def test_vote_for_news_article_version
    v = NewsArticleVersion.find 1
    Vote.vote(v, "mysession")
    v.reload
    assert_equal 1, v.votes, "first vote didn't register"
    Vote.vote(v, "mysession")
    v.reload
    assert_equal 1, v.votes, "duplicate vote registered!"
  end

end
