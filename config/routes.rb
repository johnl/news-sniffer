NewsSniffer::Application.routes.draw do
  match 'admin' => 'admin#login'
  match 'articles/:article_id/diff/:version_b/:version_a' => 'versions#diff', :as => :diff
  resources :versions do
    collection do
  get :search
  end
    member do
  post :vote
  end
  
  end

  resources :articles, :controller => 'NewsArticles' do
    collection do
      get :search
    end
  
    resources :versions
  end

  match '/' => 'versions#index'
  match '/:controller(/:action(/:id))'
end
