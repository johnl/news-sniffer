class AddHiddenToNewsArticle < ActiveRecord::Migration
  def change
    add_column :news_articles, :hidden, :boolean, :default => false, :default => false
  end
end
