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

ActiveRecord::Schema[7.1].define(version: 2024_02_29_130923) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.integer "flags", default: 0, null: false
    t.boolean "destroy_after_use", default: false, null: false
    t.datetime "valid_till"
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_access_tokens_on_created_at"
    t.index ["owner_type", "owner_id"], name: "index_access_tokens_on_owner"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
  end

  create_table "account_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "role", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "availability", default: 1, null: false
    t.datetime "status_changed_at"
    t.datetime "availability_changed_at"
    t.datetime "last_activity_at"
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.uuid "invited_by_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "user_id"], name: "index_account_users_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["availability"], name: "index_account_users_on_availability"
    t.index ["created_at"], name: "index_account_users_on_created_at"
    t.index ["invited_by_id"], name: "index_account_users_on_invited_by_id"
    t.index ["role"], name: "index_account_users_on_role"
    t.index ["status"], name: "index_account_users_on_status"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "locale", default: "en", null: false
    t.string "email"
    t.bigint "features", default: 0, null: false
    t.jsonb "limits", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "billing_data", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.integer "referral_commission_type", default: 0, null: false
    t.decimal "referral_commission", precision: 10, scale: 2
    t.decimal "referred_by_commission", precision: 10, scale: 2
    t.datetime "referral_approved_at"
    t.datetime "referral_paid_at"
    t.string "identifier", null: false
    t.string "referral_code", null: false
    t.uuid "address_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "referred_by_id"
    t.index ["created_at"], name: "index_accounts_on_created_at"
    t.index ["identifier"], name: "index_accounts_on_identifier", unique: true
    t.index ["name"], name: "index_accounts_on_name"
    t.index ["referral_code"], name: "index_accounts_on_referral_code", unique: true
    t.index ["referred_by_id"], name: "index_accounts_on_referred_by_id"
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "action_mailbox_inbound_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "address1"
    t.string "address2"
    t.string "city", limit: 60
    t.string "zipcode", limit: 15
    t.string "phone_code"
    t.string "phone_number"
    t.string "alternative_phone_code"
    t.string "alternative_phone_number"
    t.string "state_name"
    t.string "organization_name"
    t.string "national_id"
    t.text "description"
    t.string "designation"
    t.uuid "state_id"
    t.uuid "country_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["country_id"], name: "index_addresses_on_country_id"
    t.index ["created_at"], name: "index_addresses_on_created_at"
    t.index ["name"], name: "index_addresses_on_name"
    t.index ["organization_name"], name: "index_addresses_on_organization_name"
    t.index ["state_id"], name: "index_addresses_on_state_id"
  end

  create_table "channel_apis", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "webhook_url"
    t.string "webhook_username"
    t.string "webhook_password"
    t.string "webhook_secret", null: false
    t.string "name"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.jsonb "webhook_configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_apis_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_apis_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_apis_on_account_id"
    t.index ["status"], name: "index_channel_apis_on_status"
  end

  create_table "channel_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "forward_email"
    t.jsonb "imap_configurations", default: {}, null: false
    t.jsonb "smtp_configurations", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.integer "service"
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_emails_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_emails_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_emails_on_account_id"
    t.index ["email"], name: "index_channel_emails_on_email", unique: true
    t.index ["forward_email"], name: "index_channel_emails_on_forward_email", unique: true
    t.index ["status"], name: "index_channel_emails_on_status"
  end

  create_table "channel_facebook_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "page_identifier", null: false
    t.string "instagram_identifier"
    t.string "access_token", null: false
    t.jsonb "tokens", default: {}, null: false
    t.string "name"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_facebook_pages_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_facebook_pages_on_account_id_and_name"
    t.index ["account_id", "page_identifier"], name: "index_channel_facebook_pages_on_account_id_and_page_identifier", unique: true
    t.index ["account_id"], name: "index_channel_facebook_pages_on_account_id"
    t.index ["instagram_identifier"], name: "index_channel_facebook_pages_on_instagram_identifier"
    t.index ["page_identifier"], name: "index_channel_facebook_pages_on_page_identifier"
    t.index ["status"], name: "index_channel_facebook_pages_on_status"
  end

  create_table "channel_lines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "line_identifier", null: false
    t.string "secret", null: false
    t.string "token", null: false
    t.jsonb "configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_lines_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_lines_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_lines_on_account_id"
    t.index ["line_identifier"], name: "index_channel_lines_on_line_identifier", unique: true
    t.index ["status"], name: "index_channel_lines_on_status"
  end

  create_table "channel_short_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.string "full_phone_number"
    t.jsonb "tokens", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.string "service_identifier"
    t.integer "short_message_type", default: 0, null: false
    t.integer "service", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_short_messages_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_short_messages_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_short_messages_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_short_messages_on_full_phone_number", unique: true
    t.index ["service", "service_identifier"], name: "index_channel_short_messages_on_service_and_service_identifier", unique: true
    t.index ["status"], name: "index_channel_short_messages_on_status"
  end

  create_table "channel_telegrams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "token", null: false
    t.jsonb "configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_telegrams_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_telegrams_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_telegrams_on_account_id"
    t.index ["status"], name: "index_channel_telegrams_on_status"
    t.index ["token"], name: "index_channel_telegrams_on_token", unique: true
  end

  create_table "channel_twilio_sms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
  end

  create_table "channel_twitter_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "profile_identifier", null: false
    t.jsonb "tokens", default: {}, null: false
    t.boolean "handle_tweets", default: true, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_twitter_profiles_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_twitter_profiles_on_account_id_and_name"
    t.index ["account_id", "profile_identifier"], name: "idx_on_account_id_profile_identifier_4a1bc813e6", unique: true
    t.index ["account_id"], name: "index_channel_twitter_profiles_on_account_id"
    t.index ["profile_identifier"], name: "index_channel_twitter_profiles_on_profile_identifier"
    t.index ["status"], name: "index_channel_twitter_profiles_on_status"
  end

  create_table "channel_web_widgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "website_url"
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.string "secret", null: false
    t.integer "flags", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_web_widgets_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_web_widgets_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_web_widgets_on_account_id"
    t.index ["status"], name: "index_channel_web_widgets_on_status"
    t.index ["website_url"], name: "index_channel_web_widgets_on_website_url"
  end

  create_table "channel_whatsapps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.string "full_phone_number", null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "service"
    t.integer "status", default: 0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_whatsapps_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_whatsapps_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_whatsapps_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_whatsapps_on_full_phone_number", unique: true
    t.index ["service"], name: "index_channel_whatsapps_on_service"
    t.index ["status"], name: "index_channel_whatsapps_on_status"
  end

  create_table "countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "iso", null: false
    t.string "iso3", null: false
    t.string "iso_name", null: false
    t.boolean "states_required", default: false, null: false
    t.integer "numeric_code"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index "lower((iso_name)::text)", name: "index_countries_on_lower_iso_name", unique: true
    t.index ["created_at"], name: "index_countries_on_created_at"
    t.index ["iso"], name: "index_countries_on_iso", unique: true
    t.index ["iso3"], name: "index_countries_on_iso3", unique: true
  end

  create_table "country_translations", force: :cascade do |t|
    t.string "name"
    t.string "locale", null: false
    t.uuid "country_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["country_id", "locale"], name: "index_country_translations_on_country_id_and_locale", unique: true
    t.index ["country_id"], name: "index_country_translations_on_country_id"
    t.index ["locale"], name: "index_country_translations_on_locale"
    t.index ["name", "locale"], name: "index_country_translations_on_name_and_locale"
  end

  create_table "domains", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", default: ""
    t.string "value", null: false
    t.datetime "ssl_added_at"
    t.integer "status", default: 0, null: false
    t.jsonb "configurations", default: {}, null: false
    t.boolean "managed", default: false, null: false
    t.boolean "system_provided", default: false, null: false
    t.boolean "require_ssl", default: true, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_domains_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_domains_on_account_id"
    t.index ["managed"], name: "index_domains_on_managed"
    t.index ["status"], name: "index_domains_on_status"
    t.index ["system_provided"], name: "index_domains_on_system_provided"
    t.index ["value"], name: "index_domains_on_value", unique: true
  end

  create_table "state_translations", force: :cascade do |t|
    t.string "name"
    t.string "locale", null: false
    t.uuid "state_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["locale"], name: "index_state_translations_on_locale"
    t.index ["name", "locale"], name: "index_state_translations_on_name_and_locale"
    t.index ["state_id", "locale"], name: "index_state_translations_on_state_id_and_locale", unique: true
    t.index ["state_id"], name: "index_state_translations_on_state_id"
  end

  create_table "states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "abbr"
    t.uuid "country_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["abbr"], name: "index_states_on_abbr"
    t.index ["country_id"], name: "index_states_on_country_id"
    t.index ["created_at"], name: "index_states_on_created_at"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
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
    t.integer "gender", default: 0, null: false
    t.date "dob"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "provider"
    t.string "provider_uid"
    t.string "connection_token", null: false
    t.uuid "address_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["connection_token"], name: "index_users_on_connection_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["locale"], name: "index_users_on_locale"
    t.index ["name"], name: "index_users_on_name"
    t.index ["provider", "provider_uid"], name: "index_users_on_provider_and_provider_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "account_users", "accounts", on_delete: :cascade
  add_foreign_key "account_users", "users", column: "invited_by_id", on_delete: :nullify
  add_foreign_key "account_users", "users", on_delete: :cascade
  add_foreign_key "accounts", "accounts", column: "referred_by_id", on_delete: :nullify
  add_foreign_key "accounts", "addresses", on_delete: :nullify
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "countries", on_delete: :nullify
  add_foreign_key "addresses", "states", on_delete: :nullify
  add_foreign_key "channel_apis", "accounts", on_delete: :cascade
  add_foreign_key "channel_emails", "accounts", on_delete: :cascade
  add_foreign_key "channel_facebook_pages", "accounts", on_delete: :cascade
  add_foreign_key "channel_lines", "accounts", on_delete: :cascade
  add_foreign_key "channel_short_messages", "accounts", on_delete: :cascade
  add_foreign_key "channel_telegrams", "accounts", on_delete: :cascade
  add_foreign_key "channel_twitter_profiles", "accounts", on_delete: :cascade
  add_foreign_key "channel_web_widgets", "accounts", on_delete: :cascade
  add_foreign_key "channel_whatsapps", "accounts", on_delete: :cascade
  add_foreign_key "country_translations", "countries", on_delete: :cascade
  add_foreign_key "domains", "accounts", on_delete: :cascade
  add_foreign_key "state_translations", "states", on_delete: :cascade
  add_foreign_key "states", "countries", on_delete: :cascade
  add_foreign_key "users", "addresses", on_delete: :nullify
end
