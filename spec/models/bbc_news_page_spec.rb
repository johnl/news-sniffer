require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsPage::BbcNewsPage do

  before(:each) do
    @page_data_1 ||= File.read("spec/fixtures/web_pages/6072486-A.stm.html")
    @page_data_2 ||= File.read("spec/fixtures/web_pages/6072486-B.stm.html")
    @page = NewsPage::BbcNewsPage.new(@page_data_1)
  end

  it "should parse the title" do
    @page.title.should == "Son-in-law remanded over killing"
  end

  it "should parse the date in utc" do
    @page.date.should == Time.parse("Sat Oct 21 14:41:10 +0000 2006")
    @page.date.zone.should == '+00:00'
  end

  it "should calculate an MD5sum of the page content" do
    @page.text_hash.should == Digest::MD5.hexdigest(@page.content.join)
  end

  it "should parse the page content" do
    @page.content.first.should == "<b>The son-in-law of a 73-year-old Castleford widow has been charged with her murder.</b></font>"
    @page.content.last.should == "<font size=\"2\">He denied the charges against him through his solicitor and is due to appear at Leeds Crown Court on Friday."
    @page.content.size.should == 5
  end
end
