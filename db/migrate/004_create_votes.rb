class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.column "hys_comment_id", :integer
      t.column "sessionid", :string, :limit => 32
      t.column "created_at", :datetime
    end
    add_index "votes", "sessionid"
    add_index "votes", "hys_comment_id"
  end

  def self.down
    drop_table :votes
    remove_index "votes", "sessionid"
    remove_index "votes", "hys_comment_id"
  end
end
