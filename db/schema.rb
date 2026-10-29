# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_29_000000) do
  create_table "assessments", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "employee_id", null: false
    t.string "status", default: "pending", null: false
    t.json "responses_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "created_at"], name: "index_assessments_on_company_and_created_at"
    t.index ["company_id", "status", "created_at"], name: "index_assessments_on_company_status_created_at"
    t.index ["company_id"], name: "index_assessments_on_company_id"
    t.index ["employee_id"], name: "index_assessments_on_employee_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employees", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employees_on_company_id"
  end

  add_foreign_key "assessments", "companies"
  add_foreign_key "assessments", "employees"
  add_foreign_key "employees", "companies"
end
