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

ActiveRecord::Schema.define(version: 20150226220840) do

  create_table "advertiser_bulk_busters", force: :cascade do |t|
    t.string   "task_description",              null: false
    t.integer  "network_id",                    null: false
    t.string   "input_filename",                null: false
    t.integer  "percent_completed", default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "affiliate_campaign_bulk_busters", force: :cascade do |t|
    t.string   "task_description",              null: false
    t.string   "network_id",                    null: false
    t.string   "input_filename",                null: false
    t.integer  "percent_completed", default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "campaign_bulk_busters", force: :cascade do |t|
    t.string   "task_description",                                null: false
    t.string   "network_id",                                      null: false
    t.string   "advertiser_id_from_network_to_clone"
    t.string   "campaign_id_from_network_to_clone"
    t.string   "input_filename",                                  null: false
    t.integer  "percent_completed",                   default: 0, null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

end
