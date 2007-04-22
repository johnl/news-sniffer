ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  #
  map.connect 'admin', :controller => 'admin', :action => 'login'
  
  map.connect 'bbc/threads/show/:id', :controller => 'bbchysthreads', :action => 'show'
  map.connect 'bbc/threads/:action/page/:page', :controller => 'bbchysthreads'

  map.connect 'bbc/threads/:action/:id/:comment_id',
    :controller => 'bbchysthreads'
    
  map.connect 'bbc/threads/:action/:id', :controller => 'bbchysthreads'
  
  map.connect 'bbc/comments/:action/page/:page',
    :controller => 'bbchyscomments'
    
  map.connect 'bbc/comments/feed',
    :controller => 'bbchyscomments', :action => 'list_rss'

  map.connect 'bbc/comments/:action/:id', :controller => 'bbchyscomments'

  map.connect 'articles/list/page/:page', :controller => 'news_articles', :action => 'list'
  map.connect 'articles/list', :controller => 'news_articles', :action => 'list'
  
  map.connect 'articles/list_by_revision/page/:page', :controller => 'news_articles', :action => 'list_revisions'
  map.connect 'articles/list_by_revision', :controller => 'news_articles', :action => 'list_revisions'
  
  map.connect 'articles/recommended/list/page/:page', :controller => 'news_articles', :action => 'list_recommended'
  map.connect 'articles/recommended/list', :controller => 'news_articles', :action => 'list_recommended'
  
  map.connect 'articles/rss', :controller => 'news_articles', :action => 'list_rss'
  map.connect 'articles/recommended/rss', :controller => 'news_articles', :action => 'list_recommended_rss'

  map.connect 'articles/search', :controller => 'news_articles', :action => 'search'
  
  map.connect 'articles/:id/diff/:version_b/:version_a',
    :controller => 'news_articles', :action => 'diff'

  map.connect 'articles/:id/version/:version',
    :controller => 'news_articles', :action => 'show_version'
    
  map.connect 'articles/:id/rss', :controller => 'news_articles', :action => 'diff_rss'
  map.connect 'articles/:id', :controller => 'news_articles', :action => 'show'

  #map.connect ':controller/:action/:id/:comment_id'

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "pages", :action => 'summary'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
