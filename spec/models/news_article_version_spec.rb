require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NewsArticleVersion do

  before(:each) do
    NewsArticleVersion.xapian_db_path = File.join(Rails.root, 'xapian/news_article_versions-' + SecureRandom.uuid)

    @valid_attributes = { 
      :title => 'PM Brown plays down expenses row',
      :source => 'bbc',
      :guid => '7984711',
      :url => 'http://news.bbc.co.uk/1/hi/uk_politics/7984711.stm',
      :parser => 'BbcNewsPageParserV2'
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

  describe "xapian index" do
    it "should index article versions" do
      na = a_news_article_with_two_versions
      v = na.versions.first

      xapdoc = v.to_xapian_doc
      db = NewsArticleVersion.xapian_db
      xapdoc.db = db
      db << xapdoc
      db.flush

      NewsArticleVersion.xapian_search("Gordon Brown").first.should eq v
      NewsArticleVersion.xapian_search("'Gordon Brown'").first.should eq v
      NewsArticleVersion.xapian_search("Gordon -Brown").first.should eq nil
      NewsArticleVersion.xapian_search("eternal washing").first.should eq nil
      NewsArticleVersion.xapian_search("title:transparency").first.should eq nil
      NewsArticleVersion.xapian_search("transparency").first.should eq v
      NewsArticleVersion.xapian_search("residence").first.should eq v # stemmed
      NewsArticleVersion.xapian_search("title:brown").first.should eq v
      NewsArticleVersion.xapian_search("+source:bbc brown").first.should eq v
      NewsArticleVersion.xapian_search("-source:bbc brown").first.should eq nil
      puts xapdoc.to_xapian_document.terms.collect { |t| t.term }.inspect

    end

    it "should not stem the source " do
      na = a_news_article_with_two_versions
      v = na.versions.first
      xapdoc = v.to_xapian_doc
      db = NewsArticleVersion.xapian_db
      xapdoc.db = db
      NewsArticleVersion.xapian_db << xapdoc

      terms = db.rw.allterms.collect { |t| t.term }
      terms.include?("XSOURCEbbc").should be true
      terms.include?("ZXSOURCEbbc").should be false
    end


    it "should stop all stop words" do
      na = a_news_article_with_two_versions
      v = na.versions.first
      xapdoc = v.to_xapian_doc
      db = NewsArticleVersion.xapian_db
      xapdoc.db = db
      NewsArticleVersion.xapian_db << xapdoc

      terms = db.rw.allterms.collect { |t| t.term }
      terms.include?("who").should be false
    end
  end
end
