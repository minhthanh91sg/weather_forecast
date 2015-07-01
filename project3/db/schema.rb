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

ActiveRecord::Schema.define(version: 20150521041914) do

  create_table "daily_weather_readings", force: :cascade do |t|
    t.float    "rainfall_mm_last_hour"
    t.float    "wind_speed"
    t.float    "wind_direction"
    t.float    "temperature"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "station_id"
  end

  add_index "daily_weather_readings", ["station_id"], name: "index_daily_weather_readings_on_station_id"

  create_table "latest_weather_readings", force: :cascade do |t|
    t.float    "rainfall_mm_last_hour"
    t.float    "wind_speed"
    t.float    "wind_direction"
    t.float    "temperature"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "station_id"
  end

  add_index "latest_weather_readings", ["station_id"], name: "index_latest_weather_readings_on_station_id"

  create_table "post_code_locations", force: :cascade do |t|
    t.float    "lat"
    t.float    "long"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stations", force: :cascade do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "long"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "post_code_location_id"
  end

  add_index "stations", ["post_code_location_id"], name: "index_stations_on_post_code_location_id"

end
