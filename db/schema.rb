# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130421173151) do

  create_table "playlist_items", :force => true do |t|
    t.integer  "song_id"
    t.integer  "position"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "skip_counter", :default => 0, :null => false
    t.text     "skip_makers"
    t.boolean  "auto"
  end

  add_index "playlist_items", ["song_id"], :name => "index_playlist_items_on_song_id", :unique => true

  create_table "room_memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "room_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "room_memberships", ["room_id"], :name => "index_room_memberships_on_room_id"
  add_index "room_memberships", ["user_id"], :name => "index_room_memberships_on_user_id"

  create_table "rooms", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "songs", :force => true do |t|
    t.string   "artist"
    t.string   "title"
    t.string   "url"
    t.string   "filename"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "song_hash",  :default => "empty", :null => false
    t.text     "duration"
  end

  add_index "songs", ["artist"], :name => "index_songs_on_artist"
  add_index "songs", ["song_hash"], :name => "index_songs_on_song_hash", :unique => true
  add_index "songs", ["title"], :name => "index_songs_on_title"
  add_index "songs", ["url"], :name => "index_songs_on_url", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "nickname"
    t.string   "url"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "email",                  :default => "",      :null => false
    t.string   "encrypted_password",     :default => "",      :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "token",                  :default => "empty", :null => false
    t.string   "roles"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
