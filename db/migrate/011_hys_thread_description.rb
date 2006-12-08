class HysThreadDescription < ActiveRecord::Migration
  def self.up
    add_column :hys_threads, :description, :text
  end

  def self.down
    remove_column :hys_threads, :description, :text
  end
end
