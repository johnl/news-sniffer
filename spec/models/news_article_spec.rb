require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticle do
  before(:each) do
    @valid_attributes = { 
      :title => 'PM Brown plays down expenses row',
      :source => 'bbc',
      :guid => '7984711',
      :url => 'http://news.bbc.co.uk/1/hi/uk_politics/7984711.stm'
    }
    @expenses_row_article = @valid_attributes
  end

  it "should create a new instance given valid attributes" do
    NewsArticle.create!(@valid_attributes)
  end

  it "should create new NewsArticles when given an rss feed url" do
    articles = NewsArticle.create_from_rss("bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml")
    articles.size.should > 10
    articles.first.should be_a_kind_of NewsArticle
    articles.last.should be_a_kind_of NewsArticle
    articles.first.new_record?.should == false
  end

  it "should create a NewsArticleVersion from the content of its web page" do
    na = NewsArticle.create!(@valid_attributes)
    na.latest_text_hash.should be_nil
    nav = na.update_from_source
    na.latest_text_hash.should == nav.text_hash
    nav.should be_a_kind_of NewsArticleVersion
    nav.title.should == na.title
    na.versions.count.should == 1
  end

  it "should create a NewsArticleVersion when given a string containing html" do
    na = NewsArticle.create!(@expenses_row_article)
    page_data = File.read("spec/fixtures/web_pages/7984711-A.stm.html")
    nav = na.update_from_page_data(page_data)
    nav.should be_a_kind_of NewsArticleVersion
  end

  it "should not create duplicate NewsArticleVersions" do
    na = NewsArticle.create!(@expenses_row_article)
    na.versions.count.should == 0
    page_data = File.read("spec/fixtures/web_pages/7984711-A.stm.html")
    nav = na.update_from_page_data(page_data)
    na.versions.count.should == 1
    nav = na.update_from_page_data(page_data)
    nav.should be_nil
    na.versions.count.should == 1
  end    

  it "should create a new version when its page content changes" do
    na = NewsArticle.create!(@expenses_row_article)
    na.versions.count.should == 0
    page_data_1 = File.read("spec/fixtures/web_pages/7984711-A.stm.html")
    nav1 = na.update_from_page_data(page_data_1)
    na.versions.count.should == 1
    page_data_2 = File.read("spec/fixtures/web_pages/7984711-B.stm.html")
    nav2 = na.update_from_page_data(page_data_2)
    na.versions.count.should == 2
    na.reload
    na.latest_text_hash.should == nav2.text_hash
  end    
end
