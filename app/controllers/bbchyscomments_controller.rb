class BbchyscommentsController < ApplicationController
  layout 'newsniffer'
  before_filter :get_random_comment, :except => %w(vote list_rss)
  before_filter :check_admin, :only => :uncensor

  session :off, :only => %w(list_rss)
  
  def list
    @title = "Watch Your Mouth - latest censored comments"  
    @discovery_links = [ [url_for(:action => "list_rss"), "Latest censored comments"] ]
    @comments_pages, @comments =
      paginate :hys_comments, :order => 'hys_comments.updated_at desc', 
      :include => 'hys_thread',
      :conditions => ['censored = 0 and hys_comments.updated_at < (now() - INTERVAL 25 minute)']
  end
  
  def recommended
    @title = "Watch Your Mouth - recommended censored comments"  
    @comments_pages, @comments =
      paginate :hys_comments, :order => 'votes desc', 
      :include => 'hys_thread',
      :conditions => ['votes > 0']
  end
  
  def list_rss
    headers["Content-Type"] = "application/xml"
    rss = RubyRSS.new nil
    rss.title = "BBC Watch Your Mouth Censored Comment Feed"
    rss.link = "http://newsniffer.newworldodour.co.uk/"
    rss.desc = "Comments that were censored from the BBC News 'Have Your Say' section"
    comments = HysComment.find( :all, :include => 'hys_thread', :order => 'hys_comments.updated_at desc', 
      :conditions => ['hys_comments.censored = 0 and hys_comments.updated_at < (now() - INTERVAL 25 minute)'], :limit => 25 )
    rss.date = comments.first.updated_at.httpdate
    comments.each do  |c|
      c_url = url_for( :controller => 'bbchysthreads', 
        :action => 'show', :id => c.hys_thread.bbcid, :comment_id => c.bbcid ) + "##{c.bbcid}"
      text = c.text + "<br/><br/>Written by <strong>#{c.author}</strong>"
      i = RubyRSS::Item.new( c.hys_thread.title, c_url, text, c.updated_at.httpdate )
      rss.items << i
    end
    render :text => rss.generate("rss2.0")
  end

  def show
    @comment = HysComment.find_by_bbcid(params[:id], :include => 'hys_thread')
  end

  def search
    session[:wym_search] = params[:search] if params[:search]
    @search = session[:wym_search]
    @title = "Watch Your Mouth - search for '#{@search}'"
    @comments_pages, @comments =
      paginate :hys_comments,
      :conditions => ['censored = 0 and MATCH (text) AGAINST (? IN BOOLEAN MODE)', @search]
    render :action => 'list'
  end

  def uncensor
    c = HysComment.find(params[:id])
    c.censored = 1
    c.save
    flash[:notice] = 'Comment uncensored'
    redirect_to :back
  end

  def vote
    @comment = HysComment.find(params[:id])
    if is_admin?
      # An admin vote is with 5, and gets unlimited votes
      5.times { @voted = Vote.vote @comment }
    else
      @voted = Vote.vote @comment, cookies['_session_id']
    end
    unless request.xhr?
      flash[:notice] = 'Thank you for your recommendation'
      redirect_to :controller => 'bbchyscomments', :action => 'recommend'
    end
  end
end
