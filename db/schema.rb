# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100605121257) do

  create_table "comments", :force => true do |t|
    t.string  "name",     :limit => 64
    t.text    "text"
    t.string  "email",    :limit => 64
    t.integer "link_id"
    t.string  "linktype", :limit => 32
  end

  add_index "comments", ["link_id"], :name => "comments_link_id_index"
  add_index "comments", ["linktype"], :name => "comments_linktype_index"

  create_table "news_article_feed_filters", :force => true do |t|
    t.string   "name"
    t.string   "url_filter"
    t.string   "title_filter"
    t.string   "category_filter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "news_article_feeds", :force => true do |t|
    t.string   "url"
    t.string   "name"
    t.integer  "check_period",     :default => 0
    t.datetime "next_check_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source"
  end

  add_index "news_article_feeds", ["next_check_after"], :name => "index_news_article_feeds_on_next_check_after"

  create_table "news_article_version_texts", :primary_key => "news_article_version_id", :force => true do |t|
    t.text "text"
  end

  create_table "news_article_versions", :force => true do |t|
    t.integer  "news_article_id",                               :null => false
    t.string   "title",           :limit => 200,                :null => false
    t.string   "url",             :limit => 250
    t.datetime "created_at",                                    :null => false
    t.integer  "version",         :limit => 2,   :default => 0, :null => false
    t.string   "text_hash",       :limit => 32,                 :null => false
    t.integer  "votes",                          :default => 0, :null => false
  end

  add_index "news_article_versions", ["news_article_id"], :name => "news_article_versions_news_article_id_index"
  add_index "news_article_versions", ["text_hash"], :name => "news_article_versions_text_hash_index"
  add_index "news_article_versions", ["version"], :name => "version"
  add_index "news_article_versions", ["votes"], :name => "news_article_versions_votes_index"

  create_table "news_articles", :force => true do |t|
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.string   "source",           :limit => 32,                 :null => false
    t.string   "guid",             :limit => 200,                :null => false
    t.string   "url",              :limit => 250,                :null => false
    t.string   "title",            :limit => 200,                :null => false
    t.datetime "published_at"
    t.integer  "versions_count",   :limit => 2,   :default => 0, :null => false
    t.datetime "next_check_after"
    t.integer  "check_period",                    :default => 0
    t.string   "parser"
  end

  add_index "news_articles", ["check_period", "next_check_after"], :name => "index_news_articles_on_check_period_and_next_check_after"
  add_index "news_articles", ["created_at"], :name => "created_at"
  add_index "news_articles", ["guid"], :name => "news_articles_guid_index"
  add_index "news_articles", ["source"], :name => "news_articles_source_index"
  add_index "news_articles", ["updated_at"], :name => "updated_at"

  create_table "variables", :force => true do |t|
    t.string "key",   :limit => 30
    t.string "value", :limit => 250
  end

  add_index "variables", ["key"], :name => "key_key"

  create_table "votes", :force => true do |t|
    t.string   "sessionid",  :limit => 32
    t.datetime "created_at"
    t.string   "thing_type", :limit => 32
    t.integer  "thing_id"
  end

  add_index "votes", ["thing_id", "thing_type", "sessionid"], :name => "index_votes_on_thing_id_and_thing_type_and_sessionid"

end
