class DropHysFulltext < ActiveRecord::Migration
  def self.up
    execute "alter table hys_comments drop index text"
  end

  def self.down
    execute "alter table hys_comments add fulltext text (text);"
  end
end
