NewsSniffer::Application.routes.draw do
  get 'health/check'

  get 'articles/:article_id/diff/:version_b/:version_a' => 'versions#diff', :as => :diff
  resources :versions do
    collection do
      get :search
    end
  end

  resources :articles, :controller => :news_articles do
    collection do
      get :search
    end

    resources :versions
  end

  get '/' => 'versions#index'
  get '/:controller(/:action(/:id))'
end
