class AddCheckPeriodToNewsArticle < ActiveRecord::Migration
  def self.up
    add_column :news_articles, :check_period, :integer, :default => 0
    add_index :news_articles, [:check_period, :next_check_after]
  end

  def self.down
    remove_column :news_articles, :check_period
  end
end
