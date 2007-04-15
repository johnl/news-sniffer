class RevisionistaObserver < ActiveRecord::Observer
  observe NewsArticle, NewsArticleVersion, Vote

  def expire_fragment(key)
    ActionController::Base.fragment_cache_store.delete_matched(key, nil)
  end

  def after_create(model)

    if model.is_a? NewsArticleVersion
      expire_fragment(/articles\/list/) # and list_by_revision
      expire_fragment(/articles\/rss$/)
      expire_fragment(/articles\/#{model.news_article.id}/)
    end

    if model.is_a? NewsArticle
      expire_fragment(/articles\/list/) # and list_by_revision
      expire_fragment(/articles\/rss$/)
    end

    if model.is_a? Vote and model.attributes['class'] == "NewsArticleVersion"
      expire_fragment(/articles\/recommended\/list/)
      expire_fragment(/articles\/list_by_revision/)
      
      expire_fragment(/articles\/#{model.voted_object.news_article_id}/)
    end

  end

  def after_update(model)
    if model.is_a? NewsArticle
      expire_fragment(/articles\/#{model.id}/)
    end
  end

end
