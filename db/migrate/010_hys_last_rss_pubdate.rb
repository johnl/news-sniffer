class HysLastRssPubdate < ActiveRecord::Migration
  def self.up
    add_column :hys_threads, :last_rss_pubdate, :datetime
  end

  def self.down
    remove_column :hys_threads, :last_rss_pubdate
  end
end
