class NewsArticlesController < ApplicationController
  layout 'newsniffer'
  
  session :off, :except => %w(vote)

  def list
  	@title = "Revisionista latest news article list"

    @articles_pages = Paginator.new self, NewsArticle.count, 16, params[:page].to_i
    @articles = NewsArticle.find(:all, :include => 'versions', 
      :order => "news_articles.created_at desc",
      :limit => @articles_pages.items_per_page, :offset => @articles_pages.current.offset)
    render :action => 'list_articles'
  end
  
  def list_revisions
  	@title = "Revisionista latest revision list"  
    @discovery_links = [ [url_for(:action => "list_rss"), "Latest news revisions"] ]  
    @versions_pages, @versions = paginate :news_article_version, :per_page => 16,
      :include => 'news_article', :order => "news_article_versions.created_at desc",
      :conditions => 'news_article_versions.version > 0'
  end
  
  def list_recommended
    @title = "Revisionista recommended revisions"
    @discovery_links = [ [url_for(:action => "list_recommended_rss"), "Latest recommended news revisions"] ]  
    @versions_pages, @versions = paginate :news_article_version, :per_page => 16,
      :include => 'news_article',
      :order => "news_article_versions.votes desc,news_article_versions.created_at desc",
      :conditions => 'news_article_versions.version > 0 and news_article_versions.votes > 0'
    render :action => 'list_revisions'
  end
  
  def list_recommended_rss
    votes = Vote.find(:all, :conditions => "class = 'NewsArticleVersion'", :group => 'relation_id', 
      :order => 'created_at desc')
    @versions = NewsArticleVersion.find( votes.collect! { |v| v.relation_id } )
    render :layout => false
  end
  
  def list_rss
    @versions = NewsArticleVersion.find(:all, :order => 'news_article_versions.created_at desc', 
      :limit => 20,
      :conditions => 'version > 0',
      :include => 'news_article')
    render :layout => false
  end
  
  def search
   	@title = "Revision Search - Revisionista"
    @search = params[:search] || cookies[:na_search]
    cookies[:na_search] = @search

    @versions = NewsArticleVersion.ferret_search(@search, {:limit => 16, :page => params[:page]}, {:include => :news_article})
    @versions_pages = Paginator.new self, @versions.total_hits, 16, params['page']
    rescue DRb::DRbConnError
      @search = nil
      flash.now[:error] = "The search service is currently down."
    ensure
      render :action => :search
  end
  

  def show
    @article = NewsArticle.find(params[:id], :include => :versions)
    @versions = @article.versions
  end

  def show_version
    @article = NewsArticle.find(params[:id])
    @versions = @article.versions.find(:all, :order => 'id asc')
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
