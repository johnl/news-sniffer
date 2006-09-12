class PagesController < ApplicationController
  layout 'newsniffer'
  
  def summary
    @hys_comments = HysComment.find(:all, :order => 'hys_comments.updated_at desc', 
      :group => 'hys_comments.hys_thread_id',
      :conditions => ['censored = 0 and hys_comments.updated_at < (now() - INTERVAL 25 minute)'], :limit => 6)
    @news_articles = NewsArticle.find(:all, :conditions => "versions_count > 1",
      :order => "news_articles.updated_at desc", :limit => 6)

  end
end
