module NsDrb

  @@service_hash = nil

  def self.url
    config = YAML.load_file("#{RAILS_ROOT}/config/drb_service.yaml")[RAILS_ENV]
    host = config["host"]
    port = config["port"]
    "druby://#{host}:#{port}"
  end


  def self.connect
#    DRb.install_id_conv DRb::TimerIdConv.new
    DRb.start_service
    DRbObject.new(nil, url)
  end

  def self.services
    return @@service_hash unless @@service_hash.nil?
    @@service_hash = connect
  end

end
