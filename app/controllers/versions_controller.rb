require "diff_html"
class VersionsController < ApplicationController

  def index
    if params.has_key? :q
      redirect_to search_versions_url(:q => params[:q]), :status => :moved_permanently
      return
    end
    @versions = NewsArticleVersion.includes(:news_article).order('news_article_versions.id desc').paginate(:per_page => 16, :page => params[:page]  || 1)
    respond_to do |format|
      format.html
      format.rss { render :content_type => 'text/xml', :layout => false }
    end
  end

  def search
    @search = params[:q].to_s
    @versions = NewsArticleVersion.xapian_search(@search, :per_page => 16, :collapse => :news_article_id,
                                                 :page => params[:page] || 1)
    respond_to do |format|
      format.html { render :index }
      format.rss { render :index, :content_type => 'text/xml', :layout => false }
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
    if @article.hidden?
      render :text => "This article cannot be shown for legal reasons", :status => 410
    else
      @versions = @article.versions.order('version asc')
    end
  end

  def diff
    @article = NewsArticle.find(params[:article_id])
    @versions = @article.versions.order('version asc')
    @va = @article.versions.find_by_version!(params[:version_a])
    @vb = @article.versions.find_by_version!(params[:version_b])

    @diff = HTMLDiff::diff(@vb.text.split(/\n/), @va.text.split(/\n/))
    if @article.hidden?
      render :text => "This article cannot be shown for legal reasons", :status => 410
    end
  rescue ActiveRecord::RecordNotFound => e
    render :status => 404, :text => e.message
  end

end
