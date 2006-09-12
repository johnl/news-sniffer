module NewsPage
require 'digest'

class NewsPage
	attr_reader :title, :date, :content, :page_data, :text_hash
  attr_accessor :url

	def self.new(page_data = nil)
		a = allocate
		if page_data
			a.parse_page(page_data)
		end
		a
	end

	def parse_page(page_data)
		@date = Time.now()
		@content = ""
		@title = ""
	end

end

class BbcNewsPage < NewsPage

	def parse_page(page_data)
		super
		@title = $1 if page_data =~ /<meta name="Headline" content="(.*)"/i
		if page_data =~ /<meta name="OriginalPublicationDate" content="(.*)"/i
			begin
				@date = Time.parse($1)
			rescue ArgumentError
				@date = Time.now()
			end
		end
		if page_data =~ /S SF -->(.*?)<!-- E BO/m or page_data =~ /S BO -->(.*?)<!-- E BO/m
			@content = $1
			@content.gsub!(/\n|\r|\t/, '')
			@content.gsub!(/<\/?(div|img|tr|td|!--|table)[^>]*>/i, '')
			@content = @content.split(/<p>/i)
      @text_hash = Digest::MD5.hexdigest(@content.join)
		end
	end

end

end
