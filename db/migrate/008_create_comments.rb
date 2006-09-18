class CreateComments < ActiveRecord::Migration
  def self.up

    execute "alter table news_article_versions add fulltext title_text (title,text);"

    create_table :comments do |t|
      t.column :name, :string, :limit => 64
      t.column :text, :text
      t.column :email, :string, :limit => 64
      t.column :link_id, :integer
      t.column :linktype, :string, :limit => 32
    end
    add_index :comments, :link_id
    add_index :comments, :linktype

    add_column :news_article_versions, :comments_count, :integer, :default => 0
    add_index :news_article_versions, :comments_count
    
    add_column :news_article_versions, :votes, :integer, :default => 0
    add_index :news_article_versions, :votes
  end

  def self.down
    execute "alter table news_article_versions drop index 'title_text'"
    remove_index :comments, :link_id
    remove_index :comments, :linktype
    drop_table :comments

    remove_index :news_article_versions, :comments_count
    remove_column :news_article_versions, :comments_count

    remove_index :news_article_versions, :votes
    remove_column :news_article_versions, :votes
  end
end
