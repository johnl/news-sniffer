class CreateNewsArticleFeedFilters < ActiveRecord::Migration
  def self.up
    create_table :news_article_feed_filters do |t|
      t.string :name
      t.string :url_filter
      t.string :title_filter
      t.string :category_filter

      t.timestamps
    end
  end

  def self.down
    drop_table :news_article_feed_filters
  end
end
