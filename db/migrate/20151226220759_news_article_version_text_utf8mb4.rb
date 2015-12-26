class NewsArticleVersionTextUtf8mb4 < ActiveRecord::Migration
  def change
    execute "ALTER TABLE news_article_version_texts CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
