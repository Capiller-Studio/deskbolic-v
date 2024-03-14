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

ActiveRecord::Schema[7.1].define(version: 2024_02_29_105535) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "attachment_translations", force: :cascade do |t|
    t.string "alt_title"
    t.string "locale", null: false
    t.uuid "attachment_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["attachment_id", "locale"], name: "index_attachment_translations_on_attachment_id_and_locale", unique: true
    t.index ["attachment_id"], name: "index_attachment_translations_on_attachment_id"
    t.index ["locale"], name: "index_attachment_translations_on_locale"
  end

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attachment_type", default: 0, null: false
    t.string "remote_url"
    t.float "latitude"
    t.float "longitude"
    t.string "extension"
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "attachment_type"], name: "index_attachments_on_account_id_and_attachment_type"
    t.index ["account_id"], name: "index_attachments_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_attachments_on_resource"
  end

  create_table "business_hour_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "configurations", default: {}, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_business_hour_groups_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_business_hour_groups_on_account_id_and_name"
    t.index ["account_id"], name: "index_business_hour_groups_on_account_id"
  end

  create_table "business_hour_translations", force: :cascade do |t|
    t.text "reason"
    t.string "locale", null: false
    t.uuid "business_hour_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["business_hour_id", "locale"], name: "idx_on_business_hour_id_locale_71e69d1935", unique: true
    t.index ["business_hour_id"], name: "index_business_hour_translations_on_business_hour_id"
    t.index ["locale"], name: "index_business_hour_translations_on_locale"
  end

  create_table "business_hours", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "day_of_week"
    t.time "opening_time"
    t.time "closing_time"
    t.datetime "close_from"
    t.datetime "close_till"
    t.jsonb "configurations", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_business_hours_on_account_id"
    t.index ["business_hour_group_id", "close_from", "close_till"], name: "index_business_hours_on_close_time"
    t.index ["business_hour_group_id", "created_at"], name: "index_business_hours_on_business_hour_group_id_and_created_at"
    t.index ["business_hour_group_id", "day_of_week", "opening_time", "closing_time"], name: "index_business_hours_on_work_time"
    t.index ["business_hour_group_id"], name: "index_business_hours_on_business_hour_group_id"
  end

  create_table "campaign_translations", force: :cascade do |t|
    t.text "content"
    t.text "plain_content"
    t.string "locale", null: false
    t.uuid "campaign_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["campaign_id", "locale"], name: "index_campaign_translations_on_campaign_id_and_locale", unique: true
    t.index ["campaign_id"], name: "index_campaign_translations_on_campaign_id"
    t.index ["locale"], name: "index_campaign_translations_on_locale"
  end

  create_table "campaigns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "campaign_type", default: 0, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.jsonb "conditions", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "user_id"
    t.uuid "email_template_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "campaign_type"], name: "index_campaigns_on_account_id_and_campaign_type"
    t.index ["account_id", "created_at"], name: "index_campaigns_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_campaigns_on_account_id_and_name"
    t.index ["account_id", "start_at"], name: "index_campaigns_on_account_id_and_start_at"
    t.index ["account_id", "status"], name: "index_campaigns_on_account_id_and_status"
    t.index ["account_id"], name: "index_campaigns_on_account_id"
  end

  create_table "canned_response_translations", force: :cascade do |t|
    t.string "content"
    t.string "locale", null: false
    t.uuid "canned_response_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["canned_response_id", "locale"], name: "idx_on_canned_response_id_locale_63eed27ff0", unique: true
    t.index ["canned_response_id"], name: "index_canned_response_translations_on_canned_response_id"
    t.index ["locale"], name: "index_canned_response_translations_on_locale"
  end

  create_table "canned_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "identifier", null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_canned_responses_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_canned_responses_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_canned_responses_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_canned_responses_on_account_id_and_status"
    t.index ["account_id"], name: "index_canned_responses_on_account_id"
  end

  create_table "chat_bot_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_bot_id", null: false
    t.uuid "inbox_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["chat_bot_id", "inbox_id", "status"], name: "index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id_and_status"
    t.index ["chat_bot_id", "inbox_id"], name: "index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id", unique: true
    t.index ["chat_bot_id"], name: "index_chat_bot_inboxes_on_chat_bot_id"
    t.index ["created_at"], name: "index_chat_bot_inboxes_on_created_at"
    t.index ["inbox_id"], name: "index_chat_bot_inboxes_on_inbox_id"
  end

  create_table "chat_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.text "description"
    t.string "identifier", null: false
    t.integer "bot_type", default: 0, null: false
    t.string "api_url"
    t.jsonb "configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "bot_type"], name: "index_chat_bots_on_account_id_and_bot_type"
    t.index ["account_id", "created_at"], name: "index_chat_bots_on_account_id_and_created_at"
    t.index ["account_id", "flags"], name: "index_chat_bots_on_account_id_and_flags"
    t.index ["account_id", "identifier"], name: "index_chat_bots_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_chat_bots_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_chat_bots_on_account_id_and_status"
    t.index ["account_id"], name: "index_chat_bots_on_account_id"
  end

  create_table "conversation_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "last_activity_at"
    t.datetime "last_seen_at"
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.string "member_type", null: false
    t.uuid "member_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_conversation_members_on_account_id"
    t.index ["conversation_id", "member_id"], name: "index_conversation_members_on_conversation_id_and_member_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_members_on_conversation_id"
    t.index ["member_type", "member_id"], name: "index_conversation_members_on_member"
  end

  create_table "conversation_slas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "sla_policy_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_conversation_slas_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_conversation_slas_on_account_id_and_status"
    t.index ["account_id"], name: "index_conversation_slas_on_account_id"
    t.index ["conversation_id", "sla_policy_id"], name: "index_conversation_slas_on_conversation_id_and_sla_policy_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_conversation_slas_on_sla_policy_id"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.integer "source"
    t.string "external_id"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.string "identifier", null: false
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.datetime "status_changed_at"
    t.datetime "last_activity_at"
    t.datetime "first_respond_at"
    t.string "locale"
    t.uuid "account_id", null: false
    t.uuid "inbox_id", null: false
    t.uuid "campaign_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_conversations_on_account_id_and_created_at"
    t.index ["account_id", "external_id"], name: "index_conversations_on_account_id_and_external_id"
    t.index ["account_id", "identifier"], name: "index_conversations_on_account_id_and_identifier", unique: true
    t.index ["account_id", "last_activity_at"], name: "index_conversations_on_account_id_and_last_activity_at"
    t.index ["account_id", "priority"], name: "index_conversations_on_account_id_and_priority"
    t.index ["account_id", "status"], name: "index_conversations_on_account_id_and_status"
    t.index ["account_id", "title"], name: "index_conversations_on_account_id_and_title"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["campaign_id"], name: "index_conversations_on_campaign_id"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
  end

  create_table "customer_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "external_id", null: false
    t.string "connection_token", null: false
    t.uuid "customer_id", null: false
    t.uuid "inbox_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["connection_token"], name: "index_customer_inboxes_on_connection_token", unique: true
    t.index ["customer_id", "inbox_id"], name: "index_customer_inboxes_on_customer_id_and_inbox_id", unique: true
    t.index ["customer_id"], name: "index_customer_inboxes_on_customer_id"
    t.index ["external_id"], name: "index_customer_inboxes_on_external_id"
    t.index ["inbox_id"], name: "index_customer_inboxes_on_inbox_id"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "name", default: ""
    t.string "display_name"
    t.jsonb "tokens", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.string "locale", default: "en", null: false
    t.jsonb "schedular_data", default: {}, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "external_id"
    t.string "identifier"
    t.datetime "last_activity_at"
    t.integer "customer_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "gender"
    t.date "dob"
    t.string "full_phone_number"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_customers_on_account_id_and_created_at"
    t.index ["account_id", "email"], name: "index_customers_on_account_id_and_email", unique: true
    t.index ["account_id", "external_id"], name: "index_customers_on_account_id_and_external_id"
    t.index ["account_id", "full_phone_number"], name: "index_customers_on_account_id_and_full_phone_number"
    t.index ["account_id", "locale"], name: "index_customers_on_account_id_and_locale"
    t.index ["account_id", "name"], name: "index_customers_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_customers_on_account_id_and_status"
    t.index ["account_id", "username"], name: "index_customers_on_account_id_and_username", unique: true
    t.index ["account_id"], name: "index_customers_on_account_id"
    t.index ["confirmation_token"], name: "index_customers_on_confirmation_token", unique: true
    t.index ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_customers_on_unlock_token", unique: true
  end

  create_table "email_template_translations", force: :cascade do |t|
    t.string "subject"
    t.text "body"
    t.string "locale", null: false
    t.uuid "email_template_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_id", "locale"], name: "idx_on_email_template_id_locale_c1ab8a226b", unique: true
    t.index ["email_template_id"], name: "index_email_template_translations_on_email_template_id"
    t.index ["locale"], name: "index_email_template_translations_on_locale"
    t.index ["subject", "locale"], name: "index_email_template_translations_on_subject_and_locale"
  end

  create_table "email_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_templates_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_templates_on_account_id"
  end

  create_table "filters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "filter_type", default: 0, null: false
    t.jsonb "conditions", default: {}, null: false
    t.text "description"
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_filters_on_account_id_and_created_at"
    t.index ["account_id", "filter_type"], name: "index_filters_on_account_id_and_filter_type"
    t.index ["account_id", "name"], name: "index_filters_on_account_id_and_name"
    t.index ["account_id"], name: "index_filters_on_account_id"
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "help_center_article_translations", force: :cascade do |t|
    t.string "title"
    t.text "meta_title"
    t.text "content"
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.string "locale", null: false
    t.uuid "article_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id", "locale"], name: "idx_on_article_id_locale_b93b0eb9fb", unique: true
    t.index ["article_id"], name: "index_help_center_article_translations_on_article_id"
    t.index ["locale"], name: "index_help_center_article_translations_on_locale"
    t.index ["title", "locale"], name: "index_help_center_article_translations_on_title_and_locale"
  end

  create_table "help_center_articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "views_count", default: 0, null: false
    t.string "slug", null: false
    t.jsonb "configurations", default: {}, null: false
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "portal_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_help_center_articles_on_account_id"
    t.index ["portal_id", "created_at"], name: "index_help_center_articles_on_portal_id_and_created_at"
    t.index ["portal_id", "flags"], name: "index_help_center_articles_on_portal_id_and_flags"
    t.index ["portal_id", "position"], name: "index_help_center_articles_on_portal_id_and_position"
    t.index ["portal_id", "slug"], name: "index_help_center_articles_on_portal_id_and_slug", unique: true
    t.index ["portal_id", "status"], name: "index_help_center_articles_on_portal_id_and_status"
    t.index ["portal_id"], name: "index_help_center_articles_on_portal_id"
  end

  create_table "help_center_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "ancestry_depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.string "permalink", null: false
    t.string "identifier", null: false
    t.boolean "hidden", default: false, null: false
    t.string "code", null: false
    t.string "ancestry"
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "portal_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_help_center_categories_on_account_id"
    t.index ["portal_id", "ancestry"], name: "index_help_center_categories_on_portal_id_and_ancestry"
    t.index ["portal_id", "created_at"], name: "index_help_center_categories_on_portal_id_and_created_at"
    t.index ["portal_id", "flags"], name: "index_help_center_categories_on_portal_id_and_flags"
    t.index ["portal_id", "hidden"], name: "index_help_center_categories_on_portal_id_and_hidden"
    t.index ["portal_id", "identifier"], name: "index_help_center_categories_on_portal_id_and_identifier", unique: true
    t.index ["portal_id", "permalink"], name: "index_help_center_categories_on_portal_id_and_permalink", unique: true
    t.index ["portal_id", "position"], name: "index_help_center_categories_on_portal_id_and_position"
    t.index ["portal_id", "status"], name: "index_help_center_categories_on_portal_id_and_status"
    t.index ["portal_id"], name: "index_help_center_categories_on_portal_id"
  end

  create_table "help_center_category_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "resource_id", "resource_type"], name: "idx_on_category_id_resource_id_resource_type_3ce5a596a2", unique: true
    t.index ["category_id"], name: "index_help_center_category_resources_on_category_id"
    t.index ["position"], name: "index_help_center_category_resources_on_position"
    t.index ["resource_type", "resource_id"], name: "index_help_center_category_resources_on_resource"
  end

  create_table "help_center_category_translations", force: :cascade do |t|
    t.string "name"
    t.text "meta_title"
    t.text "description"
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.string "locale", null: false
    t.uuid "category_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "locale"], name: "idx_on_category_id_locale_d331d52f3b", unique: true
    t.index ["category_id"], name: "index_help_center_category_translations_on_category_id"
    t.index ["locale"], name: "index_help_center_category_translations_on_locale"
    t.index ["name", "locale"], name: "index_help_center_category_translations_on_name_and_locale"
  end

  create_table "help_center_portals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.string "locales", default: ["en"], null: false, array: true
    t.string "default_locale", default: "en", null: false
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "domain_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_help_center_portals_on_account_id_and_created_at"
    t.index ["account_id", "default_locale"], name: "index_help_center_portals_on_account_id_and_default_locale"
    t.index ["account_id", "name"], name: "index_help_center_portals_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_help_center_portals_on_account_id_and_status"
    t.index ["account_id"], name: "index_help_center_portals_on_account_id"
    t.index ["domain_id"], name: "index_help_center_portals_on_domain_id", unique: true
  end

  create_table "help_center_related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "linked_resource_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_help_center_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_help_center_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_help_center_related_resources_on_resource"
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "name"
    t.string "identifier", null: false
    t.string "external_id"
    t.string "administration_url"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "headers", default: {}, null: false
    t.jsonb "response_mapping", default: {}, null: false
    t.jsonb "params", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.uuid "customer_id", null: false
    t.uuid "identity_source_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_identities_on_account_id_and_created_at"
    t.index ["account_id", "external_id"], name: "index_identities_on_account_id_and_external_id"
    t.index ["account_id", "identifier"], name: "index_identities_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_identities_on_account_id_and_name"
    t.index ["account_id"], name: "index_identities_on_account_id"
    t.index ["customer_id", "identity_source_id"], name: "index_identities_on_customer_id_and_identity_source_id", unique: true
    t.index ["customer_id"], name: "index_identities_on_customer_id"
    t.index ["identity_source_id"], name: "index_identities_on_identity_source_id"
  end

  create_table "identity_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "source_url"
    t.text "description"
    t.integer "source_type", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "headers", default: {}, null: false
    t.jsonb "response_mapping", default: {}, null: false
    t.jsonb "params", default: {}, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_identity_sources_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_identity_sources_on_account_id_and_name"
    t.index ["account_id"], name: "index_identity_sources_on_account_id"
  end

  create_table "inbox_translations", force: :cascade do |t|
    t.text "greetings"
    t.text "notice"
    t.text "out_of_office_message"
    t.string "locale", null: false
    t.uuid "inbox_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["inbox_id", "locale"], name: "index_inbox_translations_on_inbox_id_and_locale", unique: true
    t.index ["inbox_id"], name: "index_inbox_translations_on_inbox_id"
    t.index ["locale"], name: "index_inbox_translations_on_locale"
  end

  create_table "inbox_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inbox_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_inbox_users_on_created_at"
    t.index ["inbox_id", "user_id"], name: "index_inbox_users_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_users_on_inbox_id"
    t.index ["user_id"], name: "index_inbox_users_on_user_id"
  end

  create_table "inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "display_name"
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.string "timezone", default: "UTC", null: false
    t.string "default_locale", default: "en", null: false
    t.uuid "account_id", null: false
    t.string "channel_type", null: false
    t.uuid "channel_id", null: false
    t.uuid "business_hour_group_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_inboxes_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_inboxes_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_inboxes_on_account_id_and_status"
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["business_hour_group_id"], name: "index_inboxes_on_business_hour_group_id"
    t.index ["channel_type", "channel_id"], name: "index_inboxes_on_channel"
  end

  create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "identifier", null: false
    t.text "description"
    t.string "color"
    t.jsonb "configurations", default: {}, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_labels_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_labels_on_account_id_and_identifier", unique: true
    t.index ["account_id", "title"], name: "index_labels_on_account_id_and_title"
    t.index ["account_id"], name: "index_labels_on_account_id"
  end

  create_table "macros", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "macro_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "events", default: {}, null: false
    t.jsonb "actions", default: {}, null: false
    t.boolean "managed", default: false, null: false
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_macros_on_account_id_and_created_at"
    t.index ["account_id", "macro_type"], name: "index_macros_on_account_id_and_macro_type"
    t.index ["account_id", "managed"], name: "index_macros_on_account_id_and_managed"
    t.index ["account_id", "name"], name: "index_macros_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_macros_on_account_id_and_status"
    t.index ["account_id"], name: "index_macros_on_account_id"
    t.index ["user_id"], name: "index_macros_on_user_id"
  end

  create_table "mentions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "mentioned_type", null: false
    t.uuid "mentioned_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_mentions_on_account_id"
    t.index ["mentioned_type", "mentioned_id"], name: "index_mentions_on_mentioned"
    t.index ["resource_id", "resource_type", "mentioned_id", "mentioned_type"], name: "index_mentions_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_mentions_on_resource"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content"
    t.integer "source"
    t.string "external_id"
    t.integer "status", default: 0, null: false
    t.integer "content_type", default: 0, null: false
    t.integer "visibility", default: 1, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.jsonb "sentiment", default: {}, null: false
    t.string "locale"
    t.uuid "account_id", null: false
    t.uuid "inbox_id", null: false
    t.uuid "conversation_id", null: false
    t.string "sender_type", null: false
    t.uuid "sender_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "external_id"], name: "index_messages_on_account_id_and_external_id"
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id", "content_type"], name: "index_messages_on_conversation_id_and_content_type"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id", "status"], name: "index_messages_on_conversation_id_and_status"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "visibility", default: 0, null: false
    t.string "resource_type"
    t.uuid "resource_id"
    t.uuid "user_id", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_notes_on_account_id_and_created_at"
    t.index ["account_id", "title"], name: "index_notes_on_account_id_and_title"
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notes_on_resource"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "email_flags", default: 0, null: false
    t.integer "push_flags", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "user_id"], name: "index_notification_settings_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_notification_settings_on_account_id"
    t.index ["user_id", "created_at"], name: "index_notification_settings_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "notification_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "subscription_type", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["user_id", "created_at"], name: "index_notification_subscriptions_on_user_id_and_created_at"
    t.index ["user_id", "subscription_type"], name: "idx_on_user_id_subscription_type_c17965cf4e"
    t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "event", default: 0, null: false
    t.datetime "read_at"
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "event"], name: "index_notifications_on_user_id_and_event"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name"
    t.text "description"
    t.integer "display_type", default: 0, null: false
    t.integer "value_type", default: 0, null: false
    t.jsonb "conditions", default: {}, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_properties_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_properties_on_account_id_and_name"
    t.index ["account_id"], name: "index_properties_on_account_id"
  end

  create_table "property_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "value", array: true
    t.integer "position"
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.uuid "property_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["property_id", "resource_id"], name: "index_property_resources_on_property_id_and_resource_id", unique: true
    t.index ["property_id", "value"], name: "index_property_resources_on_property_id_and_value"
    t.index ["property_id"], name: "index_property_resources_on_property_id"
    t.index ["resource_id", "created_at"], name: "index_property_resources_on_resource_id_and_created_at"
    t.index ["resource_type", "resource_id"], name: "index_property_resources_on_resource"
  end

  create_table "related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "linked_resource_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_related_resources_on_resource"
  end

  create_table "sla_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.float "response_time_limit"
    t.float "initial_response_time_limit"
    t.float "resolution_time_limit"
    t.text "description"
    t.jsonb "configurations", default: {}, null: false
    t.boolean "during_working_hours", default: false, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_sla_policies_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_sla_policies_on_account_id_and_name"
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
  end

  create_table "team_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_team_users_on_created_at"
    t.index ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_users_on_team_id"
    t.index ["user_id"], name: "index_team_users_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "identifier", null: false
    t.boolean "auto_assign", default: true, null: false
    t.integer "status", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_teams_on_account_id_and_created_at"
    t.index ["account_id", "flags"], name: "index_teams_on_account_id_and_flags"
    t.index ["account_id", "identifier"], name: "index_teams_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_teams_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_teams_on_account_id_and_status"
    t.index ["account_id"], name: "index_teams_on_account_id"
  end

  add_foreign_key "attachment_translations", "attachments", on_delete: :cascade
  add_foreign_key "business_hour_translations", "business_hours", on_delete: :cascade
  add_foreign_key "business_hours", "business_hour_groups", on_delete: :cascade
  add_foreign_key "campaign_translations", "campaigns", on_delete: :cascade
  add_foreign_key "campaigns", "email_templates", on_delete: :nullify
  add_foreign_key "canned_response_translations", "canned_responses", on_delete: :cascade
  add_foreign_key "chat_bot_inboxes", "chat_bots", on_delete: :cascade
  add_foreign_key "chat_bot_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "conversation_members", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "sla_policies", on_delete: :cascade
  add_foreign_key "conversations", "campaigns", on_delete: :nullify
  add_foreign_key "conversations", "inboxes", on_delete: :cascade
  add_foreign_key "customer_inboxes", "customers", on_delete: :cascade
  add_foreign_key "customer_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "email_template_translations", "email_templates", on_delete: :cascade
  add_foreign_key "help_center_article_translations", "help_center_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "help_center_articles", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_categories", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_category_resources", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "help_center_category_translations", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "identities", "customers", on_delete: :cascade
  add_foreign_key "identities", "identity_sources", on_delete: :cascade
  add_foreign_key "inbox_translations", "inboxes", on_delete: :cascade
  add_foreign_key "inbox_users", "inboxes", on_delete: :cascade
  add_foreign_key "inboxes", "business_hour_groups", on_delete: :nullify
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "inboxes", on_delete: :cascade
  add_foreign_key "property_resources", "properties", on_delete: :cascade
  add_foreign_key "team_users", "teams", on_delete: :cascade
end
