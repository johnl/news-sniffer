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
class RevisionistaObserver < ActiveRecord::Observer
  observe NewsArticle, NewsArticleVersion, Vote

  def expire_fragment(key)
    ActionController::Base.fragment_cache_store.delete_matched(key, nil)
  end

  def after_create(model)

    if model.is_a? NewsArticleVersion
      expire_fragment(/articles\/list/) # and list_by_revision
      expire_fragment(/articles\/rss$/)
      expire_fragment(/articles\/#{model.news_article.id}/)
    end

    if model.is_a? NewsArticle
      expire_fragment(/articles\/list/) # and list_by_revision
      expire_fragment(/articles\/rss$/)
    end

    if model.is_a? Vote and model.attributes['class'] == "NewsArticleVersion"
      expire_fragment(/articles\/recommended\/list/)
      expire_fragment(/articles\/list_by_revision/)
      
      expire_fragment(/articles\/#{model.voted_object.news_article_id}/)
    end

  end

  def after_update(model)
    if model.is_a? NewsArticle
      expire_fragment(/articles\/#{model.id}/)
    end
  end

end
