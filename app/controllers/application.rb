# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  def get_random_comment
    @random_comment = HysComment.find(:all,
      :conditions => ['censored = 0 and updated_at < now() - INTERVAL 1 hour'], 
      :order => 'rand()', :limit => 1).first
  end

  def is_admin?
    session[:admin]
  end

  def check_admin
    unless is_admin?
      flash[:error] = "You must be logged in to do that."
      redirect_to :controller => 'admin', :action => 'login'
    end
    @admin_bar = true
  end
  
  def comment_permalink_url(comment)
    url_for(:controller => 'bbchysthreads', :action => 'show',
      :id => comment.hys_thread.bbcid, :comment_id => comment.bbcid, :anchor => comment.bbcid)
  end
                                
end
