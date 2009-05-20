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
  require 'net/http'
  require 'curb'
  require 'zlib'
  
  def self.zget(url)
    @c ||= Curl::Easy.new do |c|
      c.timeout = 8
      c.connect_timeout = 8
      c.dns_cache_timeout = 600
      c.enable_cookies = false
      c.follow_location = true
      c.headers["User-Agent"] = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.4) Gecko/20060508 Firefox/1.5.0.4'
      c.headers["Accept-encoding"] = 'gzip, deflate'
    end
    @c.url = url
    @c.perform
    raw_body = StringIO.new(@c.body_str)
    body = nil
    body = Zlib::GzipReader.new(raw_body.rewind) rescue nil
    body = Zlib::DeflateReader.new(raw_body.rewind) rescue nil unless body
    (body || (raw_body.rewind;raw_body)).read
  end
  
end
