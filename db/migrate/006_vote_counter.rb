class VoteCounter < ActiveRecord::Migration
  def self.up
    add_column :hys_comments, :votes, :integer, :default => 0
    add_index :hys_comments, :votes
  end

  def self.down
    remove_index :hys_comments, :votes
    remove_column :hys_comments, :votes, :integer
  end
end
