class CommentModifiedAt < ActiveRecord::Migration
  def self.up
    add_column :hys_comments, :modified_at, :datetime
  end

  def self.down
    drop_column :hys_comments, :modified_at
  end
end
