class PagesController < ApplicationController
  layout 'newsniffer'

  session :off
  
  def summary
    @head_html = '<link rel="pingback" href="http://www.newworldodour.co.uk/blog/xmlrpc.php" />'
    when_fragment_expired( { :action => 'summary' }, 15.minutes.from_now) do
     @news_articles = NewsArticle.find(:all, :conditions => "versions_count > 1",
       :order => "news_articles.updated_at desc", :limit => 6)

     @news_articles_count = NewsArticle.count
     @news_article_versions_count = NewsArticleVersion.count
    end

  end
end
