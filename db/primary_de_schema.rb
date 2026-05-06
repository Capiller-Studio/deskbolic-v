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

ActiveRecord::Schema[8.1].define(version: 2026_05_04_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "access_account_user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "account_user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_access_account_user_roles_on_account_id"
    t.index ["account_user_id", "role_id"], name: "idx_acc_user_role_composite"
    t.index ["account_user_id"], name: "index_access_account_user_roles_on_account_user_id"
    t.index ["created_at"], name: "index_access_account_user_roles_on_created_at"
    t.index ["role_id"], name: "index_access_account_user_roles_on_role_id"
  end

  create_table "access_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_system", default: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_access_roles_on_account_id_and_name"
    t.index ["account_id"], name: "index_access_roles_on_account_id"
    t.index ["created_at"], name: "index_access_roles_on_created_at"
  end

  create_table "attachment_translations", force: :cascade do |t|
    t.string "alt_title"
    t.uuid "attachment_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["attachment_id", "locale"], name: "index_attachment_translations_on_attachment_id_and_locale", unique: true
    t.index ["attachment_id"], name: "index_attachment_translations_on_attachment_id"
    t.index ["locale"], name: "index_attachment_translations_on_locale"
  end

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "attachment_type", default: 0, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "extension"
    t.float "latitude"
    t.float "longitude"
    t.string "remote_url"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "attachment_type"], name: "index_attachments_on_account_id_and_attachment_type"
    t.index ["account_id"], name: "index_attachments_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_attachments_on_resource"
  end

  create_table "automation_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "automation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "error_message"
    t.jsonb "executed_actions", default: [], null: false
    t.datetime "executed_at", null: false
    t.integer "execution_duration_ms"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "triggered_by", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "executed_at"], name: "index_automation_executions_on_account_id_and_executed_at"
    t.index ["account_id", "status"], name: "index_automation_executions_on_account_id_and_status"
    t.index ["account_id", "triggered_by"], name: "index_automation_executions_on_account_id_and_triggered_by"
    t.index ["account_id"], name: "index_automation_executions_on_account_id"
    t.index ["automation_id", "executed_at"], name: "idx_automation_executions_timeline"
    t.index ["automation_id"], name: "index_automation_executions_on_automation_id"
    t.index ["resource_type", "resource_id"], name: "index_automation_executions_on_resource_type_and_resource_id"
  end

  create_table "automations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "actions", default: [], null: false
    t.integer "automation_type", default: 0, null: false
    t.jsonb "conditions", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "event_name"
    t.integer "flags", default: 0, null: false
    t.boolean "is_system", default: false, null: false
    t.string "name", null: false
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id"
    t.index ["account_id", "automation_type", "event_name", "status"], name: "idx_automations_event_lookup"
    t.index ["account_id", "automation_type", "status", "position"], name: "idx_automations_execution_order"
    t.index ["account_id", "created_at"], name: "index_automations_on_account_id_and_created_at"
    t.index ["account_id", "is_system"], name: "index_automations_on_account_id_and_is_system"
    t.index ["account_id", "name"], name: "index_automations_on_account_id_and_name"
    t.index ["account_id"], name: "index_automations_on_account_id"
    t.index ["user_id"], name: "index_automations_on_user_id"
  end

  create_table "business_hour_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_business_hour_groups_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_business_hour_groups_on_account_id_and_name"
    t.index ["account_id"], name: "index_business_hour_groups_on_account_id"
  end

  create_table "business_hour_translations", force: :cascade do |t|
    t.uuid "business_hour_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.text "reason"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["business_hour_id", "locale"], name: "idx_on_business_hour_id_locale_71e69d1935", unique: true
    t.index ["business_hour_id"], name: "index_business_hour_translations_on_business_hour_id"
    t.index ["locale"], name: "index_business_hour_translations_on_locale"
  end

  create_table "business_hours", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id", null: false
    t.datetime "close_from"
    t.datetime "close_till"
    t.time "closing_time"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "day_of_week"
    t.time "opening_time"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_business_hours_on_account_id"
    t.index ["business_hour_group_id", "close_from", "close_till"], name: "index_business_hours_on_close_time"
    t.index ["business_hour_group_id", "created_at"], name: "index_business_hours_on_business_hour_group_id_and_created_at"
    t.index ["business_hour_group_id", "day_of_week", "opening_time", "closing_time"], name: "index_business_hours_on_work_time"
    t.index ["business_hour_group_id"], name: "index_business_hours_on_business_hour_group_id"
  end

  create_table "campaign_translations", force: :cascade do |t|
    t.uuid "campaign_id", null: false
    t.text "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.text "plain_content"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["campaign_id", "locale"], name: "index_campaign_translations_on_campaign_id_and_locale", unique: true
    t.index ["campaign_id"], name: "index_campaign_translations_on_campaign_id"
    t.index ["locale"], name: "index_campaign_translations_on_locale"
  end

  create_table "campaigns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "campaign_type", default: 0, null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.uuid "email_template_id"
    t.datetime "end_at"
    t.string "name"
    t.datetime "start_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id"
    t.index ["account_id", "campaign_type"], name: "index_campaigns_on_account_id_and_campaign_type"
    t.index ["account_id", "created_at"], name: "index_campaigns_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_campaigns_on_account_id_and_name"
    t.index ["account_id", "start_at"], name: "index_campaigns_on_account_id_and_start_at"
    t.index ["account_id", "status"], name: "index_campaigns_on_account_id_and_status"
    t.index ["account_id"], name: "index_campaigns_on_account_id"
  end

  create_table "canned_response_translations", force: :cascade do |t|
    t.uuid "canned_response_id", null: false
    t.string "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["canned_response_id", "locale"], name: "idx_on_canned_response_id_locale_63eed27ff0", unique: true
    t.index ["canned_response_id"], name: "index_canned_response_translations_on_canned_response_id"
    t.index ["locale"], name: "index_canned_response_translations_on_locale"
  end

  create_table "canned_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "identifier", null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_canned_responses_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_canned_responses_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_canned_responses_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_canned_responses_on_account_id_and_status"
    t.index ["account_id"], name: "index_canned_responses_on_account_id"
  end

  create_table "chat_bot_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_bot_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["chat_bot_id", "inbox_id", "status"], name: "index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id_and_status"
    t.index ["chat_bot_id", "inbox_id"], name: "index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id", unique: true
    t.index ["chat_bot_id"], name: "index_chat_bot_inboxes_on_chat_bot_id"
    t.index ["created_at"], name: "index_chat_bot_inboxes_on_created_at"
    t.index ["inbox_id"], name: "index_chat_bot_inboxes_on_inbox_id"
  end

  create_table "chat_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "api_url"
    t.integer "bot_type", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "display_name"
    t.integer "flags", default: 0, null: false
    t.string "identifier", null: false
    t.string "name"
    t.integer "status", default: 0, null: false
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
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_activity_at"
    t.datetime "last_seen_at"
    t.uuid "member_id", null: false
    t.string "member_type", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_conversation_members_on_account_id"
    t.index ["conversation_id", "member_id"], name: "index_conversation_members_on_conversation_id_and_member_id", unique: true
    t.index ["conversation_id", "role"], name: "index_conversation_members_on_conversation_id_and_role"
    t.index ["conversation_id"], name: "index_conversation_members_on_conversation_id"
    t.index ["member_type", "member_id"], name: "index_conversation_members_on_member"
  end

  create_table "conversation_slas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "sla_policy_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_conversation_slas_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_conversation_slas_on_account_id_and_status"
    t.index ["account_id"], name: "index_conversation_slas_on_account_id"
    t.index ["conversation_id", "sla_policy_id"], name: "index_conversation_slas_on_conversation_id_and_sla_policy_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_conversation_slas_on_sla_policy_id"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "campaign_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "external_id"
    t.datetime "first_respond_at"
    t.string "identifier", null: false
    t.uuid "inbox_id", null: false
    t.datetime "last_activity_at"
    t.string "locale"
    t.integer "priority", default: 0, null: false
    t.integer "source"
    t.integer "status", default: 0, null: false
    t.datetime "status_changed_at"
    t.string "title"
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

  create_table "custom_field_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "custom_field_id", null: false
    t.integer "position"
    t.boolean "required_override"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["custom_field_id", "resource_type", "resource_id"], name: "idx_custom_field_resources_unique", unique: true
    t.index ["custom_field_id"], name: "index_custom_field_resources_on_custom_field_id"
    t.index ["resource_type", "resource_id"], name: "index_custom_field_resources_on_resource_type_and_resource_id"
  end

  create_table "custom_field_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "custom_field_id", null: false
    t.text "description"
    t.string "label"
    t.string "locale", null: false
    t.jsonb "options", default: [], null: false
    t.string "placeholder"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["custom_field_id", "locale"], name: "index_custom_field_translations_on_custom_field_id_and_locale", unique: true
    t.index ["custom_field_id"], name: "index_custom_field_translations_on_custom_field_id"
  end

  create_table "custom_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "entity_type", default: 0, null: false
    t.integer "field_type", default: 0, null: false
    t.integer "flags", default: 0, null: false
    t.string "key", null: false
    t.integer "position"
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "validations", default: {}, null: false
    t.index ["account_id", "created_at"], name: "index_custom_fields_on_account_id_and_created_at"
    t.index ["account_id", "entity_type"], name: "index_custom_fields_on_account_id_and_entity_type"
    t.index ["account_id", "field_type"], name: "index_custom_fields_on_account_id_and_field_type"
    t.index ["account_id", "key"], name: "index_custom_fields_on_account_id_and_key", unique: true
    t.index ["account_id", "position"], name: "index_custom_fields_on_account_id_and_position"
    t.index ["account_id"], name: "index_custom_fields_on_account_id"
  end

  create_table "customer_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "connection_token", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "customer_id", null: false
    t.string "external_id", null: false
    t.uuid "inbox_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["connection_token"], name: "index_customer_inboxes_on_connection_token", unique: true
    t.index ["customer_id", "inbox_id"], name: "index_customer_inboxes_on_customer_id_and_inbox_id", unique: true
    t.index ["customer_id"], name: "index_customer_inboxes_on_customer_id"
    t.index ["external_id"], name: "index_customer_inboxes_on_external_id"
    t.index ["inbox_id"], name: "index_customer_inboxes_on_inbox_id"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.integer "customer_type", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.string "display_name"
    t.date "dob"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "external_id"
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "full_phone_number"
    t.integer "gender"
    t.string "identifier"
    t.datetime "last_activity_at"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "locale", default: "en", null: false
    t.datetime "locked_at"
    t.string "middle_name"
    t.string "name", default: ""
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "schedular_data", default: {}, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "username"
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

  create_table "email_template_layout_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "email_template_layout_id", null: false
    t.string "locale", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_layout_id", "locale"], name: "idx_email_layout_translations_on_layout_id_and_locale", unique: true
    t.index ["email_template_layout_id"], name: "idx_on_email_template_layout_id_412d4e8613"
    t.index ["locale"], name: "index_email_template_layout_translations_on_locale"
  end

  create_table "email_template_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_template_layouts_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_template_layouts_on_account_id"
  end

  create_table "email_template_translations", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "email_template_id", null: false
    t.string "locale", null: false
    t.string "subject"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_id", "locale"], name: "idx_on_email_template_id_locale_c1ab8a226b", unique: true
    t.index ["email_template_id"], name: "index_email_template_translations_on_email_template_id"
    t.index ["locale"], name: "index_email_template_translations_on_locale"
    t.index ["subject", "locale"], name: "index_email_template_translations_on_subject_and_locale"
  end

  create_table "email_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_templates_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_templates_on_account_id"
  end

  create_table "filters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "filter_type", default: 0, null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id", "created_at"], name: "index_filters_on_account_id_and_created_at"
    t.index ["account_id", "filter_type"], name: "index_filters_on_account_id_and_filter_type"
    t.index ["account_id", "name"], name: "index_filters_on_account_id_and_name"
    t.index ["account_id"], name: "index_filters_on_account_id"
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "help_center_article_reactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "article_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "ip_address"
    t.integer "reaction_type", null: false
    t.string "session_id"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id", "ip_address"], name: "idx_on_article_id_ip_address_26c6109755", unique: true
    t.index ["article_id"], name: "index_help_center_article_reactions_on_article_id"
    t.index ["reaction_type"], name: "index_help_center_article_reactions_on_reaction_type"
  end

  create_table "help_center_article_translations", force: :cascade do |t|
    t.uuid "article_id", null: false
    t.text "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.text "meta_title"
    t.text "search_excerpt"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["article_id", "locale"], name: "idx_on_article_id_locale_b93b0eb9fb", unique: true
    t.index ["article_id", "slug"], name: "index_help_center_article_translations_on_article_id_and_slug"
    t.index ["article_id"], name: "index_help_center_article_translations_on_article_id"
    t.index ["locale"], name: "index_help_center_article_translations_on_locale"
    t.index ["title", "locale"], name: "index_help_center_article_translations_on_title_and_locale"
  end

  create_table "help_center_articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "article_type", default: 0, null: false
    t.uuid "author_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "portal_id", null: false
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "views_count", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id"], name: "index_help_center_articles_on_account_id"
    t.index ["author_id"], name: "index_help_center_articles_on_author_id"
    t.index ["portal_id", "article_type"], name: "index_help_center_articles_on_portal_id_and_article_type"
    t.index ["portal_id", "created_at"], name: "index_help_center_articles_on_portal_id_and_created_at"
    t.index ["portal_id", "flags"], name: "index_help_center_articles_on_portal_id_and_flags"
    t.index ["portal_id", "position"], name: "index_help_center_articles_on_portal_id_and_position"
    t.index ["portal_id", "status"], name: "index_help_center_articles_on_portal_id_and_status"
    t.index ["portal_id", "visibility"], name: "index_help_center_articles_on_portal_id_and_visibility"
    t.index ["portal_id"], name: "index_help_center_articles_on_portal_id"
  end

  create_table "help_center_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.string "code", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "featured", default: false, null: false
    t.integer "flags", default: 0, null: false
    t.string "icon_key"
    t.string "identifier", null: false
    t.string "permalink", null: false
    t.uuid "portal_id", null: false
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id"], name: "index_help_center_categories_on_account_id"
    t.index ["portal_id", "ancestry"], name: "index_help_center_categories_on_portal_id_and_ancestry"
    t.index ["portal_id", "created_at"], name: "index_help_center_categories_on_portal_id_and_created_at"
    t.index ["portal_id", "featured"], name: "index_help_center_categories_on_portal_id_and_featured"
    t.index ["portal_id", "flags"], name: "index_help_center_categories_on_portal_id_and_flags"
    t.index ["portal_id", "identifier"], name: "index_help_center_categories_on_portal_id_and_identifier", unique: true
    t.index ["portal_id", "permalink"], name: "index_help_center_categories_on_portal_id_and_permalink", unique: true
    t.index ["portal_id", "position"], name: "index_help_center_categories_on_portal_id_and_position"
    t.index ["portal_id", "status"], name: "index_help_center_categories_on_portal_id_and_status"
    t.index ["portal_id", "visibility"], name: "index_help_center_categories_on_portal_id_and_visibility"
    t.index ["portal_id"], name: "index_help_center_categories_on_portal_id"
  end

  create_table "help_center_category_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "position", default: 0, null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "resource_id", "resource_type"], name: "idx_on_category_id_resource_id_resource_type_3ce5a596a2", unique: true
    t.index ["category_id"], name: "index_help_center_category_resources_on_category_id"
    t.index ["position"], name: "index_help_center_category_resources_on_position"
    t.index ["resource_type", "resource_id"], name: "index_help_center_category_resources_on_resource"
  end

  create_table "help_center_category_translations", force: :cascade do |t|
    t.uuid "category_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "locale", null: false
    t.text "meta_description"
    t.string "meta_keywords", default: [], null: false, array: true
    t.text "meta_title"
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["category_id", "locale"], name: "idx_on_category_id_locale_d331d52f3b", unique: true
    t.index ["category_id"], name: "index_help_center_category_translations_on_category_id"
    t.index ["locale"], name: "index_help_center_category_translations_on_locale"
    t.index ["name", "locale"], name: "index_help_center_category_translations_on_name_and_locale"
  end

  create_table "help_center_portal_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "contact_page_subtitle"
    t.string "contact_page_title"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "footer_text"
    t.string "header_tagline"
    t.string "hero_subtitle"
    t.string "hero_title"
    t.string "locale", null: false
    t.uuid "portal_id", null: false
    t.string "search_placeholder"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["portal_id", "locale"], name: "index_help_center_portal_translations_on_portal_id_and_locale", unique: true
    t.index ["portal_id"], name: "index_help_center_portal_translations_on_portal_id"
  end

  create_table "help_center_portals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "default_locale", default: "en", null: false
    t.uuid "domain_id", null: false
    t.integer "flags", default: 0, null: false
    t.string "locales", default: ["en"], null: false, array: true
    t.string "name"
    t.integer "status", default: 0, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_help_center_portals_on_account_id_and_created_at"
    t.index ["account_id", "default_locale"], name: "index_help_center_portals_on_account_id_and_default_locale"
    t.index ["account_id", "name"], name: "index_help_center_portals_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_help_center_portals_on_account_id_and_status"
    t.index ["account_id"], name: "index_help_center_portals_on_account_id"
    t.index ["domain_id"], name: "index_help_center_portals_on_domain_id", unique: true
  end

  create_table "help_center_redirects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale"
    t.uuid "portal_id", null: false
    t.string "source_path", null: false
    t.integer "status_code", default: 301, null: false
    t.string "target_path", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["portal_id", "source_path", "locale"], name: "idx_on_portal_id_source_path_locale_07330b3b65", unique: true
    t.index ["portal_id"], name: "index_help_center_redirects_on_portal_id"
  end

  create_table "help_center_related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "linked_resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_help_center_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_help_center_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_help_center_related_resources_on_resource"
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.string "administration_url"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "custom_attributes", default: {}, null: false
    t.uuid "customer_id", null: false
    t.string "external_id"
    t.string "first_name"
    t.string "identifier", null: false
    t.uuid "identity_source_id"
    t.integer "identity_type", default: 0, null: false
    t.string "last_name"
    t.string "middle_name"
    t.string "name"
    t.jsonb "raw_response", default: {}, null: false
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
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.jsonb "headers", default: {}, null: false
    t.string "name", null: false
    t.jsonb "params", default: {}, null: false
    t.jsonb "response_mapping", default: {}, null: false
    t.integer "source_type", default: 0, null: false
    t.string "source_url"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_identity_sources_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_identity_sources_on_account_id_and_name"
    t.index ["account_id"], name: "index_identity_sources_on_account_id"
  end

  create_table "inbox_translations", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "greetings"
    t.uuid "inbox_id", null: false
    t.string "locale", null: false
    t.text "notice"
    t.text "out_of_office_message"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["inbox_id", "locale"], name: "index_inbox_translations_on_inbox_id_and_locale", unique: true
    t.index ["inbox_id"], name: "index_inbox_translations_on_inbox_id"
    t.index ["locale"], name: "index_inbox_translations_on_locale"
  end

  create_table "inbox_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_inbox_users_on_created_at"
    t.index ["inbox_id", "user_id"], name: "index_inbox_users_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_users_on_inbox_id"
    t.index ["user_id"], name: "index_inbox_users_on_user_id"
  end

  create_table "inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "business_hour_group_id"
    t.uuid "channel_id", null: false
    t.string "channel_type", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "default_locale", default: "en", null: false
    t.string "display_name"
    t.integer "flags", default: 0, null: false
    t.string "name", default: "", null: false
    t.integer "status", default: 0, null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_inboxes_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_inboxes_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_inboxes_on_account_id_and_status"
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["business_hour_group_id"], name: "index_inboxes_on_business_hour_group_id"
    t.index ["channel_type", "channel_id"], name: "index_inboxes_on_channel"
  end

  create_table "integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "provider", null: false
    t.jsonb "settings", default: {}
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "provider"], name: "index_integrations_on_account_id_and_provider", unique: true
    t.index ["account_id"], name: "index_integrations_on_account_id"
    t.index ["created_at"], name: "index_integrations_on_created_at"
  end

  create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "color"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.string "identifier", null: false
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_labels_on_account_id_and_created_at"
    t.index ["account_id", "identifier"], name: "index_labels_on_account_id_and_identifier", unique: true
    t.index ["account_id", "title"], name: "index_labels_on_account_id_and_title"
    t.index ["account_id"], name: "index_labels_on_account_id"
  end

  create_table "mentions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "mentioned_id", null: false
    t.string "mentioned_type", null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_mentions_on_account_id"
    t.index ["mentioned_type", "mentioned_id"], name: "index_mentions_on_mentioned"
    t.index ["resource_id", "resource_type", "mentioned_id", "mentioned_type"], name: "index_mentions_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_mentions_on_resource"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.text "content"
    t.integer "content_type", default: 0, null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "external_id"
    t.string "external_reply_to_id"
    t.uuid "inbox_id", null: false
    t.string "locale"
    t.uuid "sender_id", null: false
    t.string "sender_type", null: false
    t.jsonb "sentiment", default: {}, null: false
    t.integer "source"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "visibility", default: 1, null: false
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
    t.uuid "account_id", null: false
    t.text "content"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "resource_id"
    t.string "resource_type"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["account_id", "created_at"], name: "index_notes_on_account_id_and_created_at"
    t.index ["account_id", "title"], name: "index_notes_on_account_id_and_title"
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notes_on_resource"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "email_flags", default: 0, null: false
    t.integer "push_flags", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_notification_settings_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_notification_settings_on_account_id"
    t.index ["user_id", "created_at"], name: "index_notification_settings_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "notification_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "name"
    t.integer "subscription_type", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notification_subscriptions_on_user_id_and_created_at"
    t.index ["user_id", "subscription_type"], name: "idx_on_user_id_subscription_type_c17965cf4e"
    t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "event", default: 0, null: false
    t.datetime "read_at"
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "event"], name: "index_notifications_on_user_id_and_event"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "related_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "linked_resource_id", null: false
    t.string "linked_resource_type", null: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["linked_resource_type", "linked_resource_id"], name: "index_related_resources_on_linked_resource"
    t.index ["resource_id", "resource_type", "linked_resource_id", "linked_resource_type"], name: "index_related_resources_on_unique_record", unique: true
    t.index ["resource_type", "resource_id"], name: "index_related_resources_on_resource"
  end

  create_table "sla_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "inbox_id", null: false
    t.uuid "sla_policy_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_sla_inboxes_on_account_id"
    t.index ["inbox_id"], name: "index_sla_inboxes_on_inbox_id"
    t.index ["sla_policy_id", "inbox_id"], name: "index_sla_inboxes_on_sla_policy_id_and_inbox_id", unique: true
    t.index ["sla_policy_id"], name: "index_sla_inboxes_on_sla_policy_id"
  end

  create_table "sla_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.boolean "during_working_hours", default: false, null: false
    t.float "initial_response_time_limit"
    t.string "name", null: false
    t.float "resolution_time_limit"
    t.float "response_time_limit"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_sla_policies_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_sla_policies_on_account_id_and_name"
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
  end

  create_table "team_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "team_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_team_users_on_created_at"
    t.index ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_users_on_team_id"
    t.index ["user_id"], name: "index_team_users_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "auto_assign", default: true, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.integer "flags", default: 0, null: false
    t.string "identifier", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_teams_on_account_id_and_created_at"
    t.index ["account_id", "flags"], name: "index_teams_on_account_id_and_flags"
    t.index ["account_id", "identifier"], name: "index_teams_on_account_id_and_identifier", unique: true
    t.index ["account_id", "name"], name: "index_teams_on_account_id_and_name"
    t.index ["account_id", "status"], name: "index_teams_on_account_id_and_status"
    t.index ["account_id"], name: "index_teams_on_account_id"
  end

  create_table "webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "endpoint_url", null: false
    t.string "event_name", null: false
    t.uuid "integration_id", null: false
    t.jsonb "request_payload", default: {}
    t.integer "status", default: 0
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_webhook_deliveries_on_created_at"
    t.index ["event_name"], name: "index_webhook_deliveries_on_event_name"
    t.index ["integration_id"], name: "index_webhook_deliveries_on_integration_id"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
  end

  create_table "webhook_delivery_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_number", default: 1, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "error_trace"
    t.integer "http_status"
    t.text "response_body"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "webhook_delivery_id", null: false
    t.index ["created_at"], name: "index_webhook_delivery_attempts_on_created_at"
    t.index ["webhook_delivery_id"], name: "index_webhook_delivery_attempts_on_webhook_delivery_id"
  end

  add_foreign_key "access_account_user_roles", "access_roles", column: "role_id", on_delete: :cascade
  add_foreign_key "attachment_translations", "attachments", on_delete: :cascade
  add_foreign_key "automation_executions", "automations", on_delete: :cascade
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
  add_foreign_key "custom_field_resources", "custom_fields", on_delete: :cascade
  add_foreign_key "custom_field_translations", "custom_fields", on_delete: :cascade
  add_foreign_key "customer_inboxes", "customers", on_delete: :cascade
  add_foreign_key "customer_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "email_template_layout_translations", "email_template_layouts", on_delete: :cascade
  add_foreign_key "email_template_translations", "email_templates", on_delete: :cascade
  add_foreign_key "help_center_article_reactions", "help_center_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "help_center_article_translations", "help_center_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "help_center_articles", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_categories", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_category_resources", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "help_center_category_translations", "help_center_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "help_center_portal_translations", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "help_center_redirects", "help_center_portals", column: "portal_id", on_delete: :cascade
  add_foreign_key "identities", "customers", on_delete: :cascade
  add_foreign_key "identities", "identity_sources", on_delete: :cascade
  add_foreign_key "inbox_translations", "inboxes", on_delete: :cascade
  add_foreign_key "inbox_users", "inboxes", on_delete: :cascade
  add_foreign_key "inboxes", "business_hour_groups", on_delete: :nullify
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "inboxes", on_delete: :cascade
  add_foreign_key "sla_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "sla_inboxes", "sla_policies", on_delete: :cascade
  add_foreign_key "team_users", "teams", on_delete: :cascade
  add_foreign_key "webhook_deliveries", "integrations", on_delete: :cascade
  add_foreign_key "webhook_delivery_attempts", "webhook_deliveries", on_delete: :cascade
end
