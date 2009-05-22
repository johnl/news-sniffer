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
    p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    nav.new_record?.should == false
  end

  it "should not create duplicate NewsArticleVersions" do
    na = a_news_article_with_one_version
    p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_nil
    na.versions.count.should == 1
  end    
  
  describe "next_check_after" do
    it "should default to asap on create" do
      a_news_article.next_check_after.should be_close(Time.now, 10)
    end

    it "should be set to 30.minutes after the first version is found" do
      na = a_news_article
      p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
      na.update_from_page(p)
      na.next_check_after.should be_close(Time.now + 30.minutes, 10)
    end
    
    it "should be reset to 30 minutes when a new version is found" do
      na = a_news_article
      p1 = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
      na.update_from_page(p1)
      p2 = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html_with_a_change)
      na.update_from_page(p2)
      na.next_check_after.should be_close(Time.now + 30.minutes, 10)
    end
    
    it "should increase by 20% when a check is made but a new version is not found" do
      na = a_news_article
      p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
      period = 30.minutes
      30.times do
        na.update_from_page(p)
        na.next_check_after.should be_close(Time.now + period, 10)
        period = (period * 1.2).round
      end
    end
    
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

  it "should decrement the versions_count field when a new version is destroyed" do
    na = a_news_article_with_two_versions
    na.versions.first.destroy
    na.reload
    na.versions_count.should == 1
  end  

  it "should update last_version_at field after a new version is created" do
    na = a_news_article
    na.last_version_at.should be_nil
    p = WebPageParser::BbcNewsPageParserV2.new(:page => some_news_page_html)
    na.update_from_page(p)
    na.last_version_at.should be_close(Time.now, 5)
  end

  describe "due_check scope" do
    it "should exclude articles over 40 days overdue" do
      a = a_news_article(:next_check_after => Time.now + 41.days)
      NewsArticle.due_check.size.should == 0
    end
    
    it "should order articles by how overdue an update they are" do
      now = Time.now
      a = a_news_article(:next_check_after => now - 1.hour)
      b = a_news_article(:next_check_after => now - 2.hours)
      NewsArticle.due_check.should == [b,a]
    end
    
    it "should not include articles not overdue an update yet" do
      now = Time.now
      a = a_news_article(:next_check_after => now - 1.hour)
      b = a_news_article(:next_check_after => now + 1.hour)
      NewsArticle.due_check.should == [a]
    end
    
  end
end
