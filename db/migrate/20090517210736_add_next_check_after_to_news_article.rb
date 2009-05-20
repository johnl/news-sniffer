class AddNextCheckAfterToNewsArticle < ActiveRecord::Migration
  def self.up
    add_column :news_articles, :next_check_after, :datetime
  end

  def self.down
    remove_column :news_articles, :next_check_after
  end
end
