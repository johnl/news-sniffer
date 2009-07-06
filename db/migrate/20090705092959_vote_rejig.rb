class VoteRejig < ActiveRecord::Migration
  def self.up
    remove_index :votes, :name => "votes_class_index"
    remove_index :votes, :name => "votes_relation_id_index"
    remove_index :votes, :name => "votes_sessionid_index"
    rename_column :votes, :class, :thing_type
    rename_column :votes, :relation_id, :thing_id
    add_index :votes, [:thing_id, :thing_class, :sessionid]
  end

  def self.down
    raise "Can't migrate VoteRejig down"
  end
end
