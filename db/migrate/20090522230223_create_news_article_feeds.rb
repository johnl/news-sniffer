class CreateNewsArticleFeeds < ActiveRecord::Migration
  def self.up
    create_table :news_article_feeds do |t|
      t.string :url
      t.string :name
      t.integer :check_period, :default => 0
      t.datetime :next_check_after
      t.timestamps
    end
    add_index :news_article_feeds, :next_check_after
  end

  def self.down
    drop_table :news_article_feeds
  end
end
