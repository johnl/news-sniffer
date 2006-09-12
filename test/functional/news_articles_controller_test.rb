require File.dirname(__FILE__) + '/../test_helper'
require 'news_articles_controller'

# Re-raise errors caught by the controller.
class NewsArticlesController; def rescue_action(e) raise e end; end

class NewsArticlesControllerTest < Test::Unit::TestCase
  def setup
    @controller = NewsArticlesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
