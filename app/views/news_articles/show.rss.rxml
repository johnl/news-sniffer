xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do

    xml.title       "'#{h(@article.title)}' latest revisions"
    xml.link        article_url(@article)
    xml.pubDate     CGI.rfc1123_date @article.updated_at
    xml.description "Changes to the #{@article.source} article " + h(@article.url)

    @versions.reverse.each do |v|
      next if v.version == 0
      xml.item do
        xml.title       "v#{v.version}: #{h(v.title)}"
        link = diff_url(@article, v.version - 1, v.version)
        xml.link        link
        xml.pubDate     CGI.rfc1123_date v.created_at
        xml.guid        link
        xml.author      @article.source
      end
    end

  end
end
