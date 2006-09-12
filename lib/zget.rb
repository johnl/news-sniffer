      def zget(uri)
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
