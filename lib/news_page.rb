module NewsPage
require 'digest'
require 'cgi'

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

  private

  def unhtml(s)
    t = CGI::unescapeHTML(s)
    t = t.gsub(/&apos;/i, "'")
    t
  end

end

## BBC News parser - not perfect but difficult to change it now without generating unnecessary 
## new versions of old articles
class BbcNewsPage < NewsPage

	def parse_page(page_data)
		super
		@title = unhtml($1) if page_data =~ /<meta name="Headline" content="(.*)"/i
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

## Guardian.co.uk parser
class GuardianUkNewsPage < NewsPage

  def parse_page(page_data)
    super
    # Get title
    @title = unhtml($2) if page_data =~ /<title>([^|]+)\| (.*)<\/title>/i
    # Get publish date
    page_data =~ /<!-- artifact_id=(.*), built ([^)]+) -->/i
    begin
      @date = Time.parse($2)
    rescue
      @date = Time.now()
    end
    # Get body text
    if page_data =~ /<div id="GuardianArticleBody">(.*)<br id="articleend">/mi
      @content = $1
			@content.gsub!(/\n|\r|\t/, ' ')
      # strip out unwanted tags
			@content.gsub!(/<\/?(div|img|tr|td|!--|table|script|font|hr|br|iframe|a)[^>]*>/i, ' ')
			@content.gsub!(/<\/p>/i, ' ')
			@content.gsub!(/ +/, ' ') # replace repeating spaces
      @content = unhtml(@content) # translate html encoded characters
      @content = @content.split(/<p>/i)
      @text_hash = Digest::MD5.hexdigest(@content.join)
    end
  end
    
end

class IndependentUkNewsPage < NewsPage
  def parse_page(page_data)
    super
    @title = unhtml($1) if page_data =~ /meta name="DESCRIPTION" content="([^"]+)"/i
    @date = Time.now() # Independent provide no useful date
    # archived news is locked off from non-subscribers.  if so, just ignore content
    if page_data =~ /<h1>Independent Portfolio<\/h1>/mi
      return
    end
    if page_data =~ /<div id="bodyCopyContent">(.*)<div class="miniWrapper">/mi
      @content = $1
			@content.gsub!(/\n|\r|\t/, ' ')
			@content.gsub!(/<\/?(div|img|tr|td|!--|table|script|font|hr|br|iframe|a)[^>]*>/i, ' ')
			@content.gsub!(/<\/p>/i, ' ')
			@content.gsub!(/ +/, ' ')
      @content = unhtml(@content)
      @content = @content.split(/<p>/i)
      @text_hash = Digest::MD5.hexdigest(@content.join)
    end
  end
end

end
