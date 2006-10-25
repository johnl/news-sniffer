class HysObserver < ActiveRecord::Observer
  observe HysComment, HysThread
  #include ActionController::Benchmarking::ClassMethods
  include ActionController::Caching

  def self.benchmark(title, log_level = Logger::DEBUG, use_silence = true)
    yield
  end

  def after_update(model)
    if model.is_a? HysComment
      expire_fragment( "hys_thread_#{model.hys_thread.bbcid}" )
      #expire_fragment( "hys_comments_recommended_page_" + i.to_s )
    end
  end

end

HysObserver.instance
