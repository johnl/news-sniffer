require "diff_html"
class VersionsController < ApplicationController

  def index
    if params[:q].to_s.empty?
      @versions = NewsArticleVersion.paginate :per_page => 16, :page => params[:page]  || 1,
      :include => 'news_article', :order => "news_article_versions.id desc"
    else
      @search = params[:q].to_s
      @versions = NewsArticleVersion.xapian_search(@search, :per_page => 16, :collapse => :news_article_id,
                                                 :page => params[:page] || 1)
    end
    respond_to do |format|
      format.html
      format.rss { render :content_type => 'application/rss+xml', :layout => false }
    end
  end

  def show
    if params[:article_id]
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
    @versions = @article.versions.find :all, :order => 'version asc'
    @va = @article.versions.find_by_version!(params[:version_a])
    @vb = @article.versions.find_by_version!(params[:version_b])

    @diff = HTMLDiff::diff(@vb.text.split(/\n/), @va.text.split(/\n/))
  rescue ActiveRecord::RecordNotFound => e
    render :status => 404, :text => e.message
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
