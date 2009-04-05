require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticle do
  before(:each) do
    @valid_attributes = { 
      :title => 'PM Brown plays down expenses row',
      :source => 'bbc',
      :guid => '7984711',
      :url => 'http://news.bbc.co.uk/1/hi/uk_politics/7984711.stm'
    }
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
    na.latest_text_hash.should_not == nil
    nav.should be_a_kind_of NewsArticleVersion
    nav.title.should == na.title
  end
end
