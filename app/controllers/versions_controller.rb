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
    if params[:acticle_id]    
      @article = NewsArticle.find(params[:article_id])
      @version = @article.versions.find(params[:id])
    else
      @version = NewsArticleVersion.find(params[:id])
      @article = @version.news_article
    end
    @versions = @article.versions.find(:all, :order => 'version asc')    
  end
 
  def diff
    @article = NewsArticle.find(params[:article_id])
    @discovery_links = [ [url_for(:action => "diff_rss", :id => @article.id), "Latest revisions of this news article"] ]    
    @versions = @article.versions.find(:all, :order => 'version asc', :select => "id, votes, version, title")
    @va = @article.versions.find_by_version!(params[:version_a])
    @vb = @article.versions.find_by_version!(params[:version_b])
    
    @next = @versions.fetch(@va.version + 1, nil) 
    @prev = @versions.fetch(@vb.version - 1, nil) if @vb.version > 0

    @diff = HTMLDiff::diff(@vb.text.split(/\n|<p>/), @va.text.split(/\n|<p>/))
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = e.message
    redirect_to articles_url
  end
  
  def vote
    @version = NewsArticleVersion.find(params[:id])
    @vote = Vote.vote! @version, session[:session_id]
    respond_to do |format|
      format.html do
        flash[:notice] = 'Thank you for your recommendation'
        redirect_to news_article_version_url(@version.article, @version)
      end
      format.js
    end
  rescue ActiveRecord::RecordNotFound => e
  rescue ActiveRecord::RecordInvalid => e
    @exception = e
    respond_to do |format|
      format.html do
        flash[:error] = e.message
        redirect_to news_articles_url
      end
      format.js
    end
  end

end
