require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsPage::BbcNewsPage do

  before(:each) do
    @page_data_1 ||= File.read("spec/fixtures/web_pages/7984711-A.stm.html")
    @page_data_2 ||= File.read("spec/fixtures/web_pages/7984711-B.stm.html")
    @page = NewsPage::BbcNewsPage.new(@page_data_1)
  end

  it "should parse the title" do
    @page.title.should == "PM Brown plays down expenses row"
  end

  it "should parse the date in utc" do
    @page.date.should == Time.parse("Sun Apr 05 19:26:01 +0000 2009")
    @page.date.zone.should == '+00:00'
  end

  it "should calculate an MD5sum of the page content" do
    @page.text_hash.should == Digest::MD5.hexdigest(@page.content.join)
  end

  it "should parse the page content" do
    pending
    @page.content.first.should == "Gordon Brown says he has more important issues than MPs' expenses to deal with as fresh controversy grew about bills submitted by his transport secretary."
  end
end
