# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def isadmin?
    session[:admin]
  end

  def comment_permalink_url(comment)
    url_for(:controller => 'bbchysthreads', :action => 'show',
      :id => comment.hys_thread.bbcid, :comment_id => comment.bbcid, :anchor => comment.bbcid)
  end

  def comment_permalink(title, comment)
    link_to title, comment_permalink_url(comment)
  end

end
