class DropNavFulltext < ActiveRecord::Migration
  def self.up
    execute "alter table news_article_versions drop index title_and_text"
  end

  def self.down
    execute "alter table news_article_versions add fulltext title_and_text (title,text);"
  end
end
