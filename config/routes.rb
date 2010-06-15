ActionController::Routing::Routes.draw do |map|
  map.connect 'admin', :controller => 'admin', :action => 'login'
  
  
  map.diff 'articles/:article_id/diff/:version_b/:version_a',
    :controller => 'versions', :action => 'diff'

  map.resources :versions, :member => { :vote => :post }, :collection => { :search => :get }
  
  map.resources :articles, :controller => :news_articles, :collection => { :search => :get } do |article|
    article.resources :versions
  end
  
  map.connect '/', :controller => :versions, :action => :index

  map.connect ':controller/:action/:id'
end
