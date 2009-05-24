require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticleFeed do
  before(:each) do
    @valid_attributes = {
      :name => "BBC World News",
      :url => "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml",
      :check_period => 300, :next_check_after => Time.now
    }
    @more_valid_attributes = {
      :name => "BBC Policitcal News",
      :url => "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk_politics/rss.xml",
      :check_period => 300, :next_check_after => Time.now
    }
  end

  it "should create a new instance given valid attributes" do
    NewsArticleFeed.create!(@valid_attributes)
  end
  
  it "should set a default next_check_after if not set" do
    a = NewsArticleFeed.create(@valid_attributes.merge(:next_check_after => nil))
    a.next_check_after.should be_close(Time.now + a.check_period, 10)
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
end
