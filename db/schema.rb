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

ActiveRecord::Schema.define(version: 20150512234518) do

  create_table "advertiser_bulk_busters", force: :cascade do |t|
    t.string   "task_description",              null: false
    t.integer  "network_id",                    null: false
    t.string   "input_filename",                null: false
    t.integer  "percent_completed", default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "advertiser_promo_number_bulk_busters", force: :cascade do |t|
    t.string   "task_description"
    t.integer  "network_id"
    t.string   "input_filename"
    t.string   "output_filename"
    t.string   "request_type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "advertiser_ring_pool_bulk_busters", force: :cascade do |t|
    t.string   "task_description"
    t.integer  "network_id"
    t.string   "input_filename"
    t.string   "output_filename"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "affiliate_campaign_bulk_busters", force: :cascade do |t|
    t.string   "task_description",              null: false
    t.string   "network_id",                    null: false
    t.string   "input_filename",                null: false
    t.integer  "percent_completed", default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "affiliate_promo_numbers", force: :cascade do |t|
    t.string   "task_description"
    t.string   "network_id"
    t.string   "input_filename"
    t.string   "output_filename"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "bulk_trackers", force: :cascade do |t|
    t.string   "description"
    t.integer  "advertiser_count"
    t.integer  "advertiser_campaign_count"
    t.integer  "affiliate_count"
    t.integer  "affiliate_campaign_count"
    t.integer  "ring_pool_count"
    t.integer  "promo_number_count"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
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
    t.string   "total_run_time"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

end
