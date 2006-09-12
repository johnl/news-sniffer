class CreateVariables < ActiveRecord::Migration
  def self.up
    create_table :variables do |t|
      t.column :key, :string, :limit => 30
      t.column :value, :string, :limit => 250
    end  
    add_index "variables", ["key"], :name => "key_key"
  end

  def self.down
    drop_table :variables
  end
end
