ActionController::Routing::Routes.draw do |map|
  map.connect 'admin', :controller => 'admin', :action => 'login'
  
  
  map.diff 'articles/:article_id/diff/:version_b/:version_a',
    :controller => 'versions', :action => 'diff'

  map.resources :versions
  
  map.resources :articles, :controller => :news_articles do |article|
    article.resources :versions
  end
    
  map.connect '', :controller => "pages", :action => 'summary'

  map.connect ':controller/:action/:id'
end
