class NsDrb

  @@service_hash = nil

  def self.services
    return @@service_hash unless @@service_hash.nil?
#    DRb.install_id_conv DRb::TimerIdConv.new
    DRb.start_service
    host = DRB_SERVICE[:host]
    port = DRB_SERVICE[:port]
    @@service_hash = DRbObject.new(nil, 'druby://127.0.0.1:9001')
  end

end
