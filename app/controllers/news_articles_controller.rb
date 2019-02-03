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

  def index
    @title = "Latest news articles"
    @articles = NewsArticle.order('news_articles.id desc').includes(:versions).paginate :page => params[:page] || 1,
      :per_page => 20
  end

  def show
    @article = NewsArticle.find(params[:id])
    @versions = @article.versions.order('version asc').select("id, version, title, created_at")
    respond_to do |format|
      format.html
      format.rss { render :content_type => 'text/xml', :layout => false }
    end
  end

  def health
    sources = NewsArticle.group(:source).where('versions_count > 0').where(['created_at > ?', Time.now-1.day]).count
    health = sources.detect { |k,v| v < 5 } ? 'WARNING' : 'OK'
    render :json => [health, sources]
  end

end
