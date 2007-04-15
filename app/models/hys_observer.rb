class HysObserver < ActiveRecord::Observer
  observe HysComment, HysThread

  def expire_fragment(key)
    ActionController::Base.fragment_cache_store.delete_matched(key, nil)
  end

  def self.benchmark(title, log_level = Logger::DEBUG, use_silence = true)
    yield
  end

  def after_update(model)
    if model.is_a? HysComment and model.hys_thread
      expire_fragment(/bbc\/threads/)
      expire_fragment(/bbc\/comments/)
      expire_fragment(/bbchysthreads\/show\/#{model.hys_thread.bbcid}/)
    end
    if model.is_a? HysThread
      expire_fragment(/bbc\/threads/)
      expire_fragment(/bbc\/comments/)
      expire_fragment(/bbchysthreads\/show\/#{model.bbcid}/)
    end
  end

end

#HysObserver.instance
