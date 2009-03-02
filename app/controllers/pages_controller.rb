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
class PagesController < ApplicationController
  layout 'newsniffer'

  session :off
  
  def summary
    @head_html = '<link rel="pingback" href="http://www.newworldodour.co.uk/blog/xmlrpc.php" />'
    @news_articles = NewsArticle.find(:all, :conditions => "versions_count > 1",
                                      :order => "news_articles.updated_at desc", :limit => 6)
    @news_articles_count = NewsArticle.count
    @news_article_versions_count = NewsArticleVersion.count
  end
end
