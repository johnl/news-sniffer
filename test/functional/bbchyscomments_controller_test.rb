require File.dirname(__FILE__) + '/../test_helper'
require 'bbchyscomments_controller'

# Re-raise errors caught by the controller.
class BbchyscommentsController; def rescue_action(e) raise e end; end

class BbchyscommentsControllerTest < Test::Unit::TestCase
  fixtures :hys_comments, :hys_threads
  def setup
    @controller = BbchyscommentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_gets
    [:list, :recommended, :top_recommended, :list_rss].each do |action|
      get action
      assert_response :success, "#{action.to_s} didn't return success"
    end
  end

  def test_vote
    xhr :get, :vote, :id => 1
    assert_not_nil assigns['voted'], "vote didn't seem to register"
  end

#  def test_search
#    post :search, :search => 'anything'
#    assert_response :success, "search failed"
#  end
end
