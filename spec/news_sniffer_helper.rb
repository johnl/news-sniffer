def a_news_article(options = { })
  @guid_count = @guid_count.to_i + 1
  NewsArticle.create! @valid_attributes.merge(:guid => @guid_count).merge(options)
end

def some_news_page_html
  @a_news_page ||= File.read("spec/fixtures/web_pages/7984711-A.stm.html").force_encoding('iso-8859-1')
end

def some_news_page_html_with_a_change
  @a_news_page_with_a_change ||= File.read("spec/fixtures/web_pages/7984711-B.stm.html").force_encoding('iso-8859-1')
end

def some_news_page_html_with_no_title
  @some_news_page_html_with_no_title ||= File.read("spec/fixtures/web_pages/7984711-invalid.html").force_encoding('iso-8859-1')
end

def a_news_article_with_one_version
  na = a_news_article
  p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
  na.update_from_page(p)
  na.reload
end

def a_news_article_with_two_versions
  na = a_news_article
  p1 = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
  p2 = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html_with_a_change)
  na.update_from_page(p1)
  na.update_from_page(p2)
  na.reload
end

def some_rss_feed_xml
  @some_rss_feed_xml ||= File.read("spec/fixtures/rss_feeds/bbc_uk_politics.xml")
end

def some_nyt_rss_feed_xml
  @some_nyt_rss_feed_xml ||= File.read("spec/fixtures/rss_feeds/nyt_global_home.xml")
end
