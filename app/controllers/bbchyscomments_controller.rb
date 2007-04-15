class BbchyscommentsController < ApplicationController
  layout 'newsniffer'
  before_filter :check_admin, :only => :uncensor

  session :off, :except => %w(uncensor vote)

  caches_action :list, :recommended, :top_recommended, :show
  
  def list
    @title = "Watch Your Mouth - latest censored comments"  
    @discovery_links = [ [url_for(:action => "list_rss"), "Latest censored comments"] ]
    @comments_pages, @comments =
      paginate :hys_comments, :order => 'hys_comments.updated_at desc', 
      :include => 'hys_thread',
      :conditions => ["censored = #{CENSORED}"]
  end
  
  def recommended
    @title = "Watch Your Mouth - latest recommended censored comments"  
    @comments_pages, @comments =
      paginate :hys_comments, :order => 'hys_comments.updated_at desc, votes desc', 
      :include => 'hys_thread',
      :conditions => ["votes > 0 and censored = #{CENSORED}"]
  end
  
  def top_recommended
    @title = "Watch Your Mouth - top recommended censored comments"  
    @comments_pages, @comments =
      paginate :hys_comments, :order => 'votes desc', 
      :include => 'hys_thread',
      :conditions => ["votes > 0 and censored = #{CENSORED}"]
  end
  
  def list_rss
    headers["Content-Type"] = "application/xml"
    fragment_key = request.env["HTTP_HOST"].gsub(":",".") + request.env["REQUEST_URI"]
    unless @content = fragment_cache_store.read(fragment_key)
      @comments = HysComment.find( :all, :include => 'hys_thread', :order => 'hys_comments.updated_at desc', 
      :conditions => ["hys_comments.censored = #{CENSORED}"], :limit => 25 )
      @content = render_to_string :layout => false
      fragment_cache_store.write(fragment_key, @content)
    end
    render :layout => false, :text => @content
  end

  def show
    @comment = HysComment.find_by_bbcid(params[:id], :include => 'hys_thread')
  end

  def search
    @search = cookies[:wym_search] = params[:search] || cookies[:wym_search]
    cookies[:wym_search] = @search
    @title = "Comment Search - Watch Your Mouth"
    @comments_pages, @comments =
      paginate :hys_comments,
      :conditions => ["censored = #{CENSORED} and MATCH (text) AGAINST (? IN BOOLEAN MODE)", @search],
      :include => :hys_thread
  end

  def uncensor
    c = HysComment.find(params[:id])
    c.censored = 1
    c.save
    flash[:notice] = 'Comment uncensored'
    redirect_to :back
  end

  def vote
    @comment = HysComment.find(params[:id], :include => :hys_thread)
    if is_admin?
      # An admin vote is with 5, and gets unlimited votes
      5.times { @voted = Vote.vote @comment }
    else
      @voted = Vote.vote @comment, cookies['_session_id'] if request.xhr?
    end
    unless request.xhr?
      flash[:notice] = 'Thank you for your recommendation'
      redirect_to :controller => 'bbchyscomments', :action => 'recommend'
    end
  end
end
