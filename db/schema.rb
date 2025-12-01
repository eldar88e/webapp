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

ActiveRecord::Schema[8.1].define(version: 2025_11_30_220347) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "account_tiers", force: :cascade do |t|
    t.integer "bonus_percentage", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "order_min_amount", default: 0, null: false
    t.integer "order_threshold", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_account_tiers_on_title", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.bigint "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "answer_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answer_options_on_question_id"
  end

  create_table "answers", force: :cascade do |t|
    t.bigint "answer_option_id"
    t.text "answer_text"
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["answer_option_id"], name: "index_answers_on_answer_option_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id", "question_id"], name: "index_answers_on_user_id_and_question_id", unique: true
  end

  create_table "bank_cards", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "fio"
    t.string "name", null: false
    t.string "number"
    t.datetime "updated_at", null: false
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "bonus_logs", force: :cascade do |t|
    t.integer "bonus_amount"
    t.datetime "created_at", null: false
    t.string "reason"
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["source_type", "source_id"], name: "index_bonus_logs_on_source"
    t.index ["user_id"], name: "index_bonus_logs_on_user_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["task_id"], name: "index_comments_on_task_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.decimal "exchange_rate", precision: 12, scale: 2, null: false
    t.datetime "expense_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "expenseable_id"
    t.string "expenseable_type"
    t.datetime "updated_at", null: false
    t.index ["expense_date"], name: "index_expenses_on_expense_date"
    t.index ["expenseable_type", "expenseable_id"], name: "index_expenses_on_expenseable"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_favorites_on_product_id"
    t.index ["user_id", "product_id"], name: "index_favorites_on_user_id_and_product_id", unique: true
  end

  create_table "mailings", force: :cascade do |t|
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.text "message"
    t.datetime "send_at", null: false
    t.integer "target", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_mailings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "is_incoming", default: true, null: false
    t.text "text"
    t.bigint "tg_id"
    t.bigint "tg_msg_id"
    t.datetime "updated_at", null: false
    t.index ["tg_id", "created_at"], name: "index_messages_on_tg_id_created_at_desc", order: { created_at: :desc }
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.decimal "price"
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "bank_card_id"
    t.integer "bonus", default: 0, null: false
    t.datetime "created_at", null: false
    t.decimal "exchange_rate", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "has_delivery", default: false, null: false
    t.integer "msg_id"
    t.datetime "paid_at"
    t.datetime "shipped_at"
    t.integer "status", default: 0, null: false
    t.boolean "tg_msg", default: true, null: false
    t.decimal "total_amount", default: "0.0", null: false
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bank_card_id"], name: "index_orders_on_bank_card_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pghero_space_stats", force: :cascade do |t|
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "relation"
    t.text "schema"
    t.bigint "size"
    t.index ["database", "captured_at"], name: "index_pghero_space_stats_on_database_and_captured_at"
  end

  create_table "product_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_product_subscriptions_on_product_id"
    t.index ["user_id", "product_id"], name: "index_product_subscriptions_on_user_id_and_product_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "ancestry"
    t.string "brand"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "dosage_form"
    t.integer "favorites_count", default: 0, null: false
    t.string "main_ingredient"
    t.string "name"
    t.decimal "old_price", precision: 10, scale: 2
    t.integer "package_quantity"
    t.decimal "price"
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "weight"
    t.index ["ancestry"], name: "index_products_on_ancestry"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.integer "quantity"
    t.decimal "unit_cost", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id", "product_id"], name: "index_purchase_items_on_purchase_id_and_product_id", unique: true
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "TRY", null: false
    t.decimal "exchange_rate", precision: 10, scale: 2, default: "0.0"
    t.text "notes"
    t.datetime "sent_to_supplier_at"
    t.datetime "shipped_at"
    t.decimal "shipping_total", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 0, null: false
    t.datetime "stocked_at"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "text"
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "rating", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["user_id", "product_id"], name: "index_reviews_on_user_id_and_product_id", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "updated_at", null: false
    t.string "value"
    t.string "variable"
    t.index ["variable"], name: "index_settings_on_variable", unique: true
  end

  create_table "support_entries", force: :cascade do |t|
    t.text "answer"
    t.datetime "created_at", null: false
    t.string "question"
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assignee_id", null: false
    t.integer "category"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "deadline_notification_days"
    t.date "due_date"
    t.integer "position", default: 0
    t.integer "price"
    t.integer "priority"
    t.integer "stage"
    t.date "start_date"
    t.integer "task_type"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "tg_media_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_hash", null: false
    t.string "file_id"
    t.string "file_type"
    t.string "original_filename"
    t.datetime "updated_at", null: false
    t.index ["file_hash"], name: "index_tg_media_files_on_file_hash", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_tier_id"
    t.string "address"
    t.string "apartment"
    t.integer "bonus_balance", default: 0, null: false
    t.string "build"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "first_name_raw"
    t.string "home"
    t.boolean "is_blocked", default: false, null: false
    t.string "last_name"
    t.string "last_name_raw"
    t.string "middle_name"
    t.integer "order_count", default: 0, null: false
    t.boolean "password_sent", default: false, null: false
    t.string "phone_number"
    t.string "photo_url"
    t.integer "postal_code"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.boolean "started", default: false, null: false
    t.string "street"
    t.bigint "tg_id", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["account_tier_id"], name: "index_users_on_account_tier_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tg_id"], name: "index_users_on_tg_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answer_options", "questions"
  add_foreign_key "answers", "answer_options"
  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "users"
  add_foreign_key "bonus_logs", "users"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "comments", "tasks"
  add_foreign_key "comments", "users"
  add_foreign_key "favorites", "products"
  add_foreign_key "favorites", "users"
  add_foreign_key "mailings", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "bank_cards"
  add_foreign_key "orders", "users"
  add_foreign_key "product_subscriptions", "products"
  add_foreign_key "product_subscriptions", "users"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "tasks", "users"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "users", "account_tiers"
end
