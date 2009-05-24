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

ActiveRecord::Schema.define(:version => 20090524004512) do

  create_table "comments", :force => true do |t|
    t.string  "name",     :limit => 64
    t.text    "text"
    t.string  "email",    :limit => 64
    t.integer "link_id"
    t.string  "linktype", :limit => 32
  end

  add_index "comments", ["link_id"], :name => "comments_link_id_index"
  add_index "comments", ["linktype"], :name => "comments_linktype_index"

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

  create_table "news_article_versions", :force => true do |t|
    t.integer  "news_article_id"
    t.string   "title",           :limit => 200
    t.string   "url",             :limit => 250
    t.datetime "created_at"
    t.integer  "version"
    t.text     "text"
    t.string   "text_hash",       :limit => 32
    t.integer  "comments_count",                 :default => 0
    t.integer  "votes",                          :default => 0
  end

  add_index "news_article_versions", ["comments_count"], :name => "news_article_versions_comments_count_index"
  add_index "news_article_versions", ["news_article_id"], :name => "news_article_versions_news_article_id_index"
  add_index "news_article_versions", ["text_hash"], :name => "news_article_versions_text_hash_index"
  add_index "news_article_versions", ["votes"], :name => "news_article_versions_votes_index"

  create_table "news_articles", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source",           :limit => 32
    t.string   "guid",             :limit => 200
    t.string   "url",              :limit => 250
    t.string   "title",            :limit => 200
    t.datetime "published_at"
    t.string   "latest_text_hash", :limit => 32
    t.integer  "versions_count",                  :default => 0
    t.datetime "next_check_after"
    t.integer  "check_period",                    :default => 0
    t.datetime "last_version_at"
    t.string   "parser"
  end

  add_index "news_articles", ["check_period", "next_check_after"], :name => "index_news_articles_on_check_period_and_next_check_after"
  add_index "news_articles", ["guid"], :name => "altered_news_articles_guid_index"
  add_index "news_articles", ["source"], :name => "altered_news_articles_source_index"

  create_table "variables", :force => true do |t|
    t.string "key",   :limit => 30
    t.string "value", :limit => 250
  end

  add_index "variables", ["key"], :name => "key_key"

  create_table "votes", :force => true do |t|
    t.string   "sessionid",   :limit => 32
    t.datetime "created_at"
    t.string   "class",       :limit => 32
    t.integer  "relation_id"
  end

  add_index "votes", ["class"], :name => "votes_class_index"
  add_index "votes", ["relation_id"], :name => "votes_relation_id_index"
  add_index "votes", ["sessionid"], :name => "votes_sessionid_index"

end
