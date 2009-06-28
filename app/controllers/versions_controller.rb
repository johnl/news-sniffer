class VersionsController < ApplicationController
  
  layout 'newsniffer'
  
  def index
    @title = "Versions"
    @discovery_links = [ [url_for(:format => :xml), "Latest versions"] ]
    @versions = NewsArticleVersion.paginate :per_page => 16, :page => params[:page]  || 1,
      :include => 'news_article', :order => "news_article_versions.id desc"
    # TODO: xml template
  end
  
  def search
   	@title = "Search"
    @search = cookies[:na_search] = params[:search] || cookies[:na_search]
    @versions = NewsArticleVersion.paginate(:limit => 16, :page => params[:page],
                                            :include => :news_article)
    render :action => :search
  end

  def show
    @article = NewsArticle.find(params[:article_id])
    @versions = @article.versions.find(:all, :order => 'version asc')
    @version = @article.versions.find(params[:id])
  end
 
  def diff
    @article = NewsArticle.find(params[:id])
    @discovery_links = [ [url_for(:action => "diff_rss", :id => @article.id), "Latest revisions of this news article"] ]    
    @versions = @article.versions.find(:all, :order => 'version asc', :select => "id, votes, version, title")
    @va = @article.versions.find_by_version!(params[:version_a])
    @vb = @article.versions.find_by_version!(params[:version_b])
    
    @next = @versions.fetch(@va.version + 1, nil) 
    @prev = @versions.fetch(@vb.version - 1, nil) if @vb.version > 0

    @diff = HTMLDiff::diff(@vb.text.split(/\n|<p>/), @va.text.split(/\n|<p>/))
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = e.message
    redirect_to :action => :list
  end
  
  def vote
    @version = NewsArticleVersion.find(params[:id])
    if is_admin?
      # An admin vote is with 5, and gets unlimited votes
      5.times { @voted = Vote.vote @version }
    else
      @voted = Vote.vote @version, cookies['_session_id']
    end
    unless request.xhr?
      flash[:notice] = 'Thank you for your recommendation'
      redirect_to :controller => 'news_articles', :action => 'list' #FIXME
    end
  end

end
