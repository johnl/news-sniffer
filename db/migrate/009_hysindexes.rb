class Hysindexes < ActiveRecord::Migration
  def self.up
    add_index :hys_comments, :updated_at
  end

  def self.down
    remove_index :hys_comments, :updated_at
  end
end
