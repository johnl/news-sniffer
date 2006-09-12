class NewsArticlesController < ApplicationController

  layout 'newsniffer'
  
  session :off, :except => %w(search)

  def list
  	@title = "Revisionista latest news article list"
    @discovery_links = [ [url_for(:action => "list_rss"), "Latest news revisions"] ]
    @articles_pages, @articles = paginate :news_article, :per_page => 20,
      :order => "news_articles.created_at desc"
  end
  
  def list_revisions
  	@title = "Revisionista latest revision list"  
    @discovery_links = [ [url_for(:action => "list_rss"), "Latest news revisions"] ]  
    @articles_pages, @articles = paginate :news_article, :per_page => 20,
      :conditions => "versions_count > 1",
      :order => "news_articles.updated_at desc"  
    render :action => :list
  end
  
  def list_rss
    @articles = NewsArticle.find(:all, :order => 'updated_at desc', 
      :limit => 15,
      :conditions => 'versions_count > 1',
      :include => 'versions')
    render :layout => false
  end
  
  def search
   	@title = "Revisionista revision search"
    session[:na_search] = params[:search] if params[:search]
    @search = session[:na_search]
    @title = @title + " for '#{@search}'" if @search
    @articles_pages, @articles = paginate :news_article, :per_page => 20,
      :conditions => ["MATCH (news_article_versions.text) AGAINST (? IN BOOLEAN MODE)",
        @search ],
      :include => 'versions',
      :order => "news_articles.updated_at desc"  
    render :action => :list  
  end
  

  def show
    @article = NewsArticle.find(params[:id], :include => :news_article_versions)
    @versions = @article.news_article_versions
  end

  def show_version
    @article = NewsArticle.find(params[:id])
    @versions = @article.news_article_versions.find(:all, :order => 'id asc')
    @versions.each do |v|
      @version = v
      break if v.id == params[:version].to_i
      @prev_version = v
    end
  end
  
  def diff_rss
      @article = NewsArticle.find(params[:id], :include => 'versions')
      @versions = @article.versions
      render :layout => false
  end

  def diff
    @article = NewsArticle.find(params[:id], :include => :versions)
    @discovery_links = [ [url_for(:action => "diff_rss", :id => @article.id), "Latest revisions of this news article"] ]    
    @versions = @article.versions
    @va = @versions.fetch(params['version_a'].to_i, nil)
    @vb = @versions.fetch(params['version_b'].to_i, nil)
  	@title = "Revisionista '#{@article.title}' diff viewer (#{@vb.version}/#{@va.version})"
    if @va.nil? or @vb.nil?
      raise ActiveRecord::RecordNotFound, "version not found"
    end
    
    @next = @versions.fetch(@va.version + 1, nil) 
    @prev = @versions.fetch(@vb.version - 1, nil) if @vb.version > 0

    @diff = HTMLDiff::diff(@vb.text.split('<p>'), @va.text.split('<p>'))
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Article or version not found"
    redirect_to :action => :list
  end
end
