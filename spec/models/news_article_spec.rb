require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticle do

  before(:each) do
    @valid_attributes = { 
      :title => 'PM Brown plays down expenses row',
      :source => 'bbc',
      :guid => '7984711',
      :url => 'http://news.bbc.co.uk/1/hi/uk_politics/7984711.stm'
    }
    @more_valid_attributes = @valid_attributes.merge({ :guid => '7984712' })
    @expenses_row_article = @valid_attributes
  end

  it "should create a new instance given valid attributes" do
    a_news_article
  end

  it "should create new NewsArticles when given an rss feed url" do
    articles = NewsArticle.create_from_rss("bbc", "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml")
    articles.size.should > 10
    articles.first.should be_a_kind_of NewsArticle
    articles.last.should be_a_kind_of NewsArticle
    articles.first.new_record?.should == false
  end

  it "should create a NewsArticleVersion from the content of its web page" do
    na = a_news_article
    nav = na.update_from_source
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 1
  end

  it "should create a NewsArticleVersion when given a string containing html" do
    na = a_news_article
    nav = na.update_from_page_data(some_news_page_html)
    nav.should be_a_kind_of NewsArticleVersion
    nav.new_record?.should == false
  end

  it "should not create duplicate NewsArticleVersions" do
    na = a_news_article_with_one_version
    nav = na.update_from_page_data(some_news_page_html)
    nav.should be_nil
    na.versions.count.should == 1
  end    

  it "should create a new version when its page content changes" do
    na = a_news_article_with_two_versions
    na.versions.count.should == 2
  end

  it "should update the latest_text_hash when a new version is created" do
    na = a_news_article_with_two_versions
    na.latest_text_hash.should == na.versions.find(:first, :order => 'id desc').text_hash
  end

  it "should increment the versions_count field when a new version is created" do
    na = a_news_article_with_two_versions
    na.versions_count.should == 2
  end

  it "should decrement the versions_count field when a new version if destroyed" do
    na = a_news_article_with_two_versions
    na.versions.first.destroy
    na.reload
    na.versions_count.should == 1
  end  

  it "should exclude articles over 40 days old when using the recently_updated scope" do
    na = a_news_article
    na = NewsArticle.create!(@more_valid_attributes.merge({ :updated_at => Time.now - 40.days}))
    NewsArticle.count.should == 2
    NewsArticle.recently_updated.count.should == 1
  end
end
