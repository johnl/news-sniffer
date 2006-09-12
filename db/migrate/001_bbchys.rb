class Bbchys < ActiveRecord::Migration
  def self.up
    create_table "hys_threads", :options => "ENGINE=MyISAM"  do |t|
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "bbcid", :mediumint
      t.column "title", :string, :limit => 255, :null => false
      t.column "rsssize", :integer
    end
    add_index "hys_threads", ["bbcid"], :name => "bbcid_key"

    create_table "hys_comments", :options => "ENGINE=MyISAM" do |t|
      t.column "hys_thread_id", :integer
      t.column "created_at", :datetime
      t.column "bbcid", :mediumint
      t.column "updated_at", :datetime
      t.column "text", :text
      t.column "author", :string, :limit => 128
      t.column "censored", :tinyint, :default => 1
    end
    add_index "hys_comments", ["hys_thread_id"], :name => "hys_thread_id_key"
    add_index "hys_comments", ["bbcid"], :name => "bbcid_key"
  end

  def self.down
    drop_table "hys_comments"
    drop_table "hys_threads"
  end
end
