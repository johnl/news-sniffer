class CreateNewsArticle < ActiveRecord::Migration
  def self.up
    create_table "news_articles" do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :source, :string, :limit => 32
      t.column :guid, :string, :limit => 200
      t.column :url, :string, :limit => 250
      t.column :title, :string, :limit => 200
      t.column :published_at, :datetime
      t.column :latest_text_hash, :string, :limit => 32
    end
    add_index :news_articles, :guid
    add_index :news_articles, :source
    create_table "news_article_versions" do |t|
      t.column :news_article_id, :integer
      t.column :title, :string, :limit => 200
      t.column :url, :string, :limit => 250
      t.column :created_at, :datetime
      t.column :version, :integer
      t.column :text, :text
      t.column :text_hash, :string, :limit => 32
    end
    add_index :news_article_versions, :news_article_id
    add_index :news_article_versions, :text_hash
  end

  def self.down
    drop_table "news_article_versions"
    drop_table "news_articles"
  end
end
