require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticle do

  before(:each) do
    @valid_attributes = { 
      :title => 'PM Brown plays down expenses row',
      :source => 'bbc',
      :guid => '7984711',
      :url => 'http://news.bbc.co.uk/1/hi/uk_politics/7984711.stm',
      :parser => 'BbcNewsPageParserV5'
    }
    @more_valid_attributes = @valid_attributes.merge({ :guid => '7984712' })
    @expenses_row_article = @valid_attributes
  end

  it "should create a new instance given valid attributes" do
    a_news_article
  end

  it "should create a NewsArticleVersion from the content of its web page" do
    na = a_news_article
    nav = na.update_from_source
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 1
  end

  it "should create a NewsArticleVersion when given a string containing html" do
    na = a_news_article
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    nav.new_record?.should == false
  end

  it "should not create a new NewsArticleVersion if it has not changed since the last check" do
    na = a_news_article_with_one_version
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_nil
    na.versions.count.should == 1
  end
  
  it "should not create a new NewsArticleVersion if it has been seen more than once before already" do
    na = a_news_article
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 1
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html_with_a_change)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 2
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 3
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html_with_a_change)
    nav = na.update_from_page(p)
    nav.should be_a_kind_of NewsArticleVersion
    na.versions.count.should == 4
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    nav = na.update_from_page(p)
    nav.should == nil
    na.versions.count.should == 4    
  end
  
  describe "next_check_after" do
    it "should default to asap on create" do
      a_news_article.next_check_after.should be_within(10).of(Time.now)
    end

    it "should be set to 30.minutes after the first version is found" do
      na = a_news_article
      p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
      na.update_from_page(p)
      na.next_check_after.should be_within(10).of(Time.now + 30.minutes)
    end
    
    it "should be reset to 30 minutes when a new version is found" do
      na = a_news_article
      p1 = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
      na.update_from_page(p1)
      p2 = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html_with_a_change)
      na.update_from_page(p2)
      na.next_check_after.should be_within(10).of(Time.now + 30.minutes)
    end
    
    it "should increase by 20% when a check is made but a new version is not found" do
      na = a_news_article
      p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
      period = 30.minutes
      30.times do
        na.update_from_page(p)
        na.next_check_after.should be_within(10).of(Time.now + period)
        period = (period * 1.2).round
      end
    end
    
    it "should increase when a check is made but a new version is invalid" do
      na = a_news_article
      p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html_with_no_title)
      na.update_from_page(p)
      na.reload
      na.next_check_after.should be_within(10).of(Time.now + 30.minutes)
    end
    
  end
  
  it "should create a new version when its page content changes" do
    na = a_news_article_with_two_versions
    na.versions.count.should == 2
  end

  it "should update the latest_text_hash when a new version is created" do
    na = a_news_article_with_two_versions
    na.latest_text_hash.should == na.versions.order('id desc').first.text_hash
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
  
  it "should count it's versions by hash" do
    na = a_news_article_with_two_versions
    p = WebPageParser::BbcNewsPageParserV5.new(:page => some_news_page_html)
    na.update_from_page(p)
    na.versions.count.should == 3
    na.count_versions_by_hash(na.versions[0].text_hash).should == 2
    na.count_versions_by_hash(na.versions[1].text_hash).should == 1
  end

  describe "due_check scope" do
    
    it "should exclude articles with a nil next_check_after field" do
      a = a_news_article
      a.update_attribute(:next_check_after, nil) # can't set this on create as it set pre-validation
      NewsArticle.count.should == 1
      NewsArticle.due_check.size.should == 0
    end
    
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
