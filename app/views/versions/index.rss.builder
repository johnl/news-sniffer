xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    if @search
      xml.title "News Sniffer Search for: #{@search}"
      xml.description "Revisions matching the search #{@search}"
    else
      xml.title       "News Sniffer latest revisions"
      xml.description "The latest revisions on all news articles being monitored by News Sniffer"
    end
    xml.link        versions_url
    xml.pubDate     CGI.rfc1123_date @versions.first.created_at

    @versions.reverse.each do |v|
      xml.item do
        xml.title       "v#{v.version}: #{h(v.title)}"
        link = version_url(v)
        xml.link        link
        xml.pubDate     CGI.rfc1123_date v.created_at
        xml.guid        link
        xml.author      v.news_article.source
      end
    end

  end
end
