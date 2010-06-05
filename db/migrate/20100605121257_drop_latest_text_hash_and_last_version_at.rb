class DropLatestTextHashAndLastVersionAt < ActiveRecord::Migration
  def self.up
    remove_column :news_articles, :latest_text_hash
    remove_column :news_articles, :last_version_at
  end

  def self.down
    add_column :news_articles, :latest_text_hash, :string, :limit => 32
    add_column :news_articles, :last_version_at, :datetime
  end
end
