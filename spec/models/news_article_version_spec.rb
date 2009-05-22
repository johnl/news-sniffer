require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticleVersion do

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
  
  it "should increment the version number for each new version" do
    na = a_news_article_with_two_versions
    versions = na.versions.collect { |v| v.version  }
    versions.max.should == 1
    versions.min.should == 0
  end
end
