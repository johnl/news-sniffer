module NsDrb

  def self.local=(b)
    @local = b  
  end

  def self.local?
    @local
  end

  def self.url
    config = YAML.load_file("#{RAILS_ROOT}/config/drb_service.yaml")[RAILS_ENV]
    host = config["host"]
    port = config["port"]
    "druby://#{host}:#{port}"
  end
  
  def self.services
    #return @service_hash unless @@service_hash.nil?
    return @service_hash ||= local? ? local_services : remote_services
  end

  def self.remote_services
    DRb.start_service
    DRbObject.new(nil, url)
  end

  def self.local_services
    { 
      :news_article_version_ferret => NewsArticleVersion.ferret_init_index(),
      :fragment_cache => ActiveSupport::Cache::FileStore.new("#{RAILS_ROOT}/tmp/cache/fragment_cache/#{RAILS_ENV}")
    }
  end

end
