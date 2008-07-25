#    News Sniffer
#    Copyright (C) 2007-2008 John Leach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
