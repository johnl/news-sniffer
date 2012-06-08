require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticleFeed do
  before(:each) do
    @valid_attributes = {
      :name => "BBC World News",
      :url => "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml",
      :check_period => 300, :next_check_after => Time.now, :source => 'bbc'
    }
    @more_valid_attributes = {
      :name => "BBC Policitcal News",
      :url => "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk_politics/rss.xml",
      :check_period => 300, :next_check_after => Time.now, :source => 'bbc'
    }
  end

  it "should create a new instance given valid attributes" do
    NewsArticleFeed.create!(@valid_attributes)
  end
  
  describe "next_check_after" do
    it "should be set to asap on create" do
      a = NewsArticleFeed.create(@valid_attributes.merge(:next_check_after => nil))
      a.next_check_after.should be_within(10).of(Time.now)
    end
    
    it "should be set to Time.now + check_period when update_next_check_after is called" do
      a = NewsArticleFeed.create(@valid_attributes.merge(:next_check_after => nil))
      a.update_next_check_after!
      a.next_check_after.should be_within(10).of(Time.now + a.check_period)
    end
  end
  
  describe "due_check scope" do
    it "should only return NewsArticleFeeds with a next_check_due in the past" do
      a = NewsArticleFeed.create!(@valid_attributes.merge(:next_check_after => Time.now + 5.minutes))
      b = NewsArticleFeed.create!(@more_valid_attributes.merge(:next_check_after => Time.now - 60.minutes))
      NewsArticleFeed.due_check.collect { |a| a.next_check_after }.max.should < Time.now
    end
  end
  
  
  describe "get_rss_entries" do
    it "return hashes for each entry in the given rss feed xml" do
      entries = NewsArticleFeed.new.get_rss_entries(some_rss_feed_xml)
      entries.size.should == 57
      entries.first.should be_a Hash
      entries.collect { |e| e.class }.uniq.size.should == 1  
    end

    it "return hashes with title, guid and link keys" do
      entry = NewsArticleFeed.new.get_rss_entries(some_rss_feed_xml).first
      entry[:title].should_not be_nil
      entry[:guid].should_not be_nil
      entry[:link].should_not be_nil
    end
  
    it "should convert html entities in titles to utf8"
    
  end

  describe "create_from_rss" do
    it "should create new NewsArticles when given rss feed data" do
      f = NewsArticleFeed.create!(@valid_attributes)
      articles = f.create_news_articles(some_rss_feed_xml)
      articles.size.should be_within(10).of(57)
      articles.first.should be_a_kind_of NewsArticle
      articles.collect { |e| e.class }.uniq.size.should == 1  
      articles.first.new_record?.should == false
    end

    it "should set the source on new NewsArticles" do
      f = NewsArticleFeed.create!(@valid_attributes)
      articles = f.create_news_articles(some_rss_feed_xml)
      articles.first.source.should == @valid_attributes[:source]
    end
    
    it "should not create NewsArticles for entries that match NewsArticleFeedFilters" do
      NewsArticleFeedFilter.create!(:name => "Test", :url_filter => 'bbc')
      f = NewsArticleFeed.create!(@valid_attributes)
      articles = f.create_news_articles(some_rss_feed_xml)
      articles.size.should == 0      
    end
    
  end

  
end
