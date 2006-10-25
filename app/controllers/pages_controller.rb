class PagesController < ApplicationController
  layout 'newsniffer'
  
  def summary
    when_fragment_expired( { :action => 'summary' }, 1.minutes.from_now) do
     @hys_comments = HysComment.find(:all, :order => 'hys_comments.updated_at desc', 
       :group => 'hys_comments.hys_thread_id',
       :conditions => ['censored = 0 and hys_comments.updated_at < (now() - INTERVAL 25 minute)'],
       :limit => 6, :include => 'hys_thread')
     @news_articles = NewsArticle.find(:all, :conditions => "versions_count > 1",
       :order => "news_articles.updated_at desc", :limit => 6)

     @hys_comments_count = HysComment.count
     @hys_comments_censored_count = HysComment.count(:conditions => 'censored = 0')
     @news_articles_count = NewsArticle.count
     @news_article_versions_count = NewsArticleVersion.count
    end

  end
end
