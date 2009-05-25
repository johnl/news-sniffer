require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticleFeedFilter do
  before(:each) do
    @valid_attributes = {
      :name => "BBC Sport",
      :url_filter => "/sport[0-9]/",
      :title_filter => "",
      :category_filter => ""
    }
    @naff =  NewsArticleFeedFilter.new(@valid_attributes)
    @bad_url = "http://news.bbc.co.uk/sport1/hi/football/teams/c/celtic/8067244.stm"
    @good_url = "http://news.bbc.co.uk/1/hi/england/beds/bucks/herts/8066515.stm"
  end

  it "should create a new instance given valid attributes" do
    NewsArticleFeedFilter.create!(@valid_attributes)
  end
  
  it "should match urls against the url filter" do
    @naff.allows?(:url => nil).should == true
    @naff.allows?(:url => @bad_url).should == false
    @naff.allows?(:url => @good_url).should == true
  end
  
  it "should not match urls when there is no url filter defined" do
    NewsArticleFeedFilter.new.allows?(:url => @bad_url).should == true
  end
  
  it "should match titles against the title filter"
  it "should not match titles when there is no title filter defined"
  it "should match categories against the category filter"
  it "should not match categories when there is no category filter defined"
  
end
