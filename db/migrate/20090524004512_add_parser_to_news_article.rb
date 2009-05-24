class AddParserToNewsArticle < ActiveRecord::Migration
  def self.up
    add_column :news_articles, :parser, :string
  end

  def self.down
    remove_column :news_articles, :parser
  end
end
