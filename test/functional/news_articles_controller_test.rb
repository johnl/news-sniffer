require File.dirname(__FILE__) + '/../test_helper'
require 'news_articles_controller'

# Re-raise errors caught by the controller.
class NewsArticlesController; def rescue_action(e) raise e end; end

class NewsArticlesControllerTest < Test::Unit::TestCase
  fixtures :news_articles, :news_article_versions

  def setup
    @controller = NewsArticlesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_gets
    [:list, :list_revisions, :list_recommended, :search, :list_recommended_rss, :list_rss].each do |action|
      get action
      assert_response :success, "#{action.to_s} didn't return success"
    end
  end

  def test_list_versions
    get :list_revisions
    assert_no_tag :content => /annan views lebanon devastation version 0/i
    assert_tag :content => /annan views lebanon devastation version 1/i
    assert_no_tag :content => /egypt defender version 0/i
  end

  def test_search
    post :search, :search => 'annan'
    #assert_tag :content => /lebanon devastation/i
  end
end
