class HysObserver < ActiveRecord::Observer
  observe HysComment, HysThread, Vote

  def expire_fragment(key)
    ActionController::Base.fragment_cache_store.delete_matched(key, nil)
  end

  def after_save(model)

    if model.is_a? HysComment
      expire_fragment(/bbc\/threads\/all/)
      expire_fragment(/bbc\/threads\/mostcensored/)
      expire_fragment(/bbc\/comments\/feed/)

      expire_fragment(/bbc\/comments\/list/)
      if model.hys_thread
        expire_fragment(/bbc\/threads\/show\/#{model.hys_thread.bbcid}/)
      end
    end

    if model.is_a? HysThread
      expire_fragment(/bbc\/threads\/all/)
      expire_fragment(/bbc\/threads\/mostcensored/)

      expire_fragment(/bbc\/threads\/show\/#{model.bbcid}/)
    end
    
    if model.is_a? Vote and model.attributes['class'] == "HysComment"
      expire_fragment(/bbc\/threads\/all/)
      expire_fragment(/bbc\/threads\/mostcensored/)
      
      expire_fragment(/bbc\/comments\/list/)
      expire_fragment(/bbc\/comments\/recommended/)
      expire_fragment(/bbc\/comments\/top_recommended/)
      
      expire_fragment(/bbc\/threads\/show\/#{model.voted_object.hys_thread.bbcid}/)
    end

  end

end
