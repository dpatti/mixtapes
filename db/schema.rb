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

ActiveRecord::Schema.define(version: 20150525185452) do

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.text     "comment"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "deleted",    default: false
  end

  create_table "contests", force: :cascade do |t|
    t.integer "year"
    t.string  "season", limit: 255
  end

  add_index "contests", ["year", "season"], name: "index_contests_on_year_and_season", unique: true

  create_table "guesses", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mixtape_id"
    t.integer  "user_guessed_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mixtapes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.binary   "cover"
    t.string   "owner",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "user_id"
    t.integer  "contest_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "artist",       limit: 255
    t.string   "album",        limit: 255
    t.integer  "track_number"
    t.integer  "duration"
    t.string   "file",         limit: 255
    t.binary   "cover_art"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "mixtape_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",    limit: 255
    t.string   "uid",         limit: 255
    t.string   "name",        limit: 255
    t.string   "email",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.datetime "accessed_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

end
