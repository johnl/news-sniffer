class Votechanges < ActiveRecord::Migration
  def self.up
    remove_index :votes, "hys_comment_id"
    remove_column :votes, "hys_comment_id"
    add_column :votes, "class", :string, :limit => 32
    add_column :votes, "relation_id", :integer
    add_index :votes, "class"
    add_index :votes, "relation_id"
  end

  def self.down
    add_column :votes, "hys_comment_id", :integer
    add_index :votes, "hys_comment_id"

    remove_index :votes, "class"
    remove_index :votes, "sessionid"
    remove_column :votes, "relation_id"
    remove_column :votes, "class"
  end
end
