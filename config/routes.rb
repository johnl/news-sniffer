ActionController::Routing::Routes.draw do |map|
  map.connect 'admin', :controller => 'admin', :action => 'login'
  
  
  map.connect 'articles/:id/diff/:version_b/:version_a',
    :controller => 'news_articles', :action => 'diff'

  map.connect 'articles/:id/version/:version',
    :controller => 'news_articles', :action => 'show_version'

  map.resources :versions
  
  map.resources :articles, :controller => :news_articles do |article|
    article.resources :versions
  end
    
  map.connect '', :controller => "pages", :action => 'summary'

  map.connect ':controller/:action/:id'
end
