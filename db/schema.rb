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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170829033329) do

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",    default: false
  end

  create_table "guesses", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.integer  "user_guessed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "last_reads", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.datetime "time"
  end

  add_index "last_reads", ["user_id", "mixtape_id"], name: "index_last_reads_on_user_id_and_mixtape_id", unique: true

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "song_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mixtapes", force: :cascade do |t|
    t.string   "name"
    t.binary   "cover"
    t.string   "owner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string   "title"
    t.string   "artist"
    t.string   "album"
    t.integer  "track_number"
    t.integer  "duration"
    t.string   "file"
    t.binary   "cover_art"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mixtape_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "accessed_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

  create_table "votes", force: :cascade do |t|
    t.integer  "award_id"
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
