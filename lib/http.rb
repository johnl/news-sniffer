module HTTP
  require 'open-uri'
  def self.head_hash(url)
    t = url.scan /http:\/\/([^\/]+)\/(.*)$/
    host = t.first.first
    path = t.first.last
    Net::HTTP.start(host, 80) do |http|
      begin
        @response = http.head('/'+path)
      rescue Timeout::Error
				log_warn("head_hash: Timeout::Error on #{url}")
        return false
      end
    end
    @response.to_hash
  end
  
  def self.remote_filesize(url)
    r = head_hash(url)
    return false unless r and r.has_key? 'content-length'
    r['content-length'].first.to_i
  end

  def self.remote_etag(url)
    r = head_hash(url)
    return false unless r and r.has_key? 'etag'
    r['etag']
  end
      
      def self.zget(uri)
        @data = nil
        
        begin
          @userAgent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.4) Gecko/20060508 Firefox/1.5.0.4'
          @acceptEncoding = 'gzip'
          @uri = open(uri, 'rb',
                     'User-Agent' => @userAgent,
                     'Accept-Encoding' => @acceptEncoding)
          if @uri.content_encoding.include? 'gzip'
            @data = Zlib::GzipReader.new(@uri).read
          else
            @data = @uri.read
          end
          @uri.close
        rescue TypeError
          return nil
        rescue SocketError
          return nil
        rescue OpenURI::HTTPError
          raise 'HTTPError: 404 Not found'
        end
        
        return @data
      end

end
