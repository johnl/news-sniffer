#    News Sniffer
#    Copyright (C) 2007-2008 John Leach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
class NewsArticlesController < ApplicationController
  layout 'newsniffer'
  
  session :off, :except => %w(vote)
  caches_action :list, :list_revisions, :list_recommended

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
    @versions = NewsArticleVersion.find_by_sql("SELECT news_article_versions.created_at, news_article_versions.title, votes, news_article_versions.id, version, news_article_id, news_articles.id, news_articles.source
      FROM news_article_versions, votes, news_articles 
      WHERE votes.class = 'NewsArticleVersion' AND votes.relation_id = news_article_versions.id 
      AND news_article_versions.news_article_id = news_articles.id ORDER BY votes.id desc LIMIT 20")
    render :layout => false
  end
  
  def list_rss
    headers["Content-Type"] = "application/xml"
    fragment_key = (request.env["HTTP_HOST"]||"").gsub(":",".") + request.env["REQUEST_URI"]
    unless @content = fragment_cache_store.read(fragment_key)
      @versions = NewsArticleVersion.find(:all, :order => 'news_article_versions.created_at desc', 
        :limit => 20,
        :conditions => 'version > 0',
        :include => 'news_article')
      @content = render_to_string :layout => false
      fragment_cache_store.write(fragment_key, @content)
    end
    render :layout => false, :text => @content
  end
  
  def search
   	@title = "Revision Search - Revisionista"
    @search = cookies[:na_search] = params[:search] || cookies[:na_search]

    if @search 
      @versions = NewsArticleVersion.ferret_search(@search, {:limit => 16, :page => params[:page]}, {:include => :news_article})
      @versions_pages = Paginator.new self, @versions.total_hits, 16, params['page']
    end
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
      @versions = @article.versions.sort
      render :layout => false
  end

  def diff
    @article = NewsArticle.find(params[:id], :include => :versions)
    @discovery_links = [ [url_for(:action => "diff_rss", :id => @article.id), "Latest revisions of this news article"] ]    
    @versions = @article.versions.sort
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
