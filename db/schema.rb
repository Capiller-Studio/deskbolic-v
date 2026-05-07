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

ActiveRecord::Schema[8.1].define(version: 2026_04_21_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "destroy_after_use", default: false, null: false
    t.integer "flags", default: 0, null: false
    t.uuid "owner_id", null: false
    t.string "owner_type", null: false
    t.string "token", null: false
    t.integer "token_type", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "valid_till"
    t.index ["created_at"], name: "index_access_tokens_on_created_at"
    t.index ["owner_type", "owner_id"], name: "index_access_tokens_on_owner"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
    t.index ["token_type"], name: "index_access_tokens_on_token_type"
  end

  create_table "account_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "availability", default: 1, null: false
    t.datetime "availability_changed_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "invited_by_id"
    t.datetime "last_activity_at"
    t.integer "role", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.datetime "status_changed_at"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
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
    t.uuid "address_id"
    t.jsonb "billing_data", default: {}, null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.jsonb "data", default: {}, null: false
    t.string "email"
    t.bigint "features", default: 0, null: false
    t.string "identifier", null: false
    t.jsonb "limits", default: {}, null: false
    t.string "locale", default: "en", null: false
    t.string "name", null: false
    t.datetime "referral_approved_at"
    t.string "referral_code", null: false
    t.decimal "referral_commission", precision: 10, scale: 2
    t.integer "referral_commission_type", default: 0, null: false
    t.datetime "referral_paid_at"
    t.decimal "referred_by_commission", precision: 10, scale: 2
    t.uuid "referred_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_accounts_on_created_at"
    t.index ["identifier"], name: "index_accounts_on_identifier", unique: true
    t.index ["name"], name: "index_accounts_on_name"
    t.index ["referral_code"], name: "index_accounts_on_referral_code", unique: true
    t.index ["referred_by_id"], name: "index_accounts_on_referred_by_id"
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "action_mailbox_inbound_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "alternative_phone_code"
    t.string "alternative_phone_number"
    t.string "city", limit: 60
    t.uuid "country_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "designation"
    t.string "name"
    t.string "national_id"
    t.string "organization_name"
    t.string "phone_code"
    t.string "phone_number"
    t.uuid "state_id"
    t.string "state_name"
    t.string "title"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "zipcode", limit: 15
    t.index ["country_id"], name: "index_addresses_on_country_id"
    t.index ["created_at"], name: "index_addresses_on_created_at"
    t.index ["name"], name: "index_addresses_on_name"
    t.index ["organization_name"], name: "index_addresses_on_organization_name"
    t.index ["state_id"], name: "index_addresses_on_state_id"
  end

  create_table "affiliate_commissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_profile_id", null: false
    t.uuid "affiliate_referral_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "commission_type", default: 0
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "exchange_rate", precision: 10, scale: 6, default: "1.0"
    t.decimal "original_amount", precision: 10, scale: 2, null: false
    t.uuid "original_commission_id"
    t.string "original_currency", null: false
    t.integer "status", default: 0
    t.uuid "transaction_record_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["affiliate_profile_id"], name: "index_affiliate_commissions_on_affiliate_profile_id"
    t.index ["affiliate_referral_id"], name: "index_affiliate_commissions_on_affiliate_referral_id"
    t.index ["commission_type"], name: "index_affiliate_commissions_on_commission_type"
    t.index ["created_at"], name: "index_affiliate_commissions_on_created_at"
    t.index ["original_commission_id"], name: "index_affiliate_commissions_on_original_commission_id"
    t.index ["status"], name: "index_affiliate_commissions_on_status"
    t.index ["transaction_record_id"], name: "index_affiliate_commissions_on_transaction_record_id"
  end

  create_table "affiliate_payouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_profile_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}
    t.integer "status", default: 0
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["affiliate_profile_id"], name: "index_affiliate_payouts_on_affiliate_profile_id"
    t.index ["created_at"], name: "index_affiliate_payouts_on_created_at"
    t.index ["status"], name: "index_affiliate_payouts_on_status"
  end

  create_table "affiliate_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "bank_account_data", default: {}
    t.decimal "commission_rate", precision: 5, scale: 2
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", default: "USD", null: false
    t.integer "holding_days"
    t.decimal "max_earnings_per_account", precision: 10, scale: 2
    t.string "referral_code", null: false
    t.integer "tenure_months"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_affiliate_profiles_on_created_at"
    t.index ["currency"], name: "index_affiliate_profiles_on_currency"
    t.index ["referral_code"], name: "index_affiliate_profiles_on_referral_code", unique: true
    t.index ["user_id"], name: "index_affiliate_profiles_on_user_id"
  end

  create_table "affiliate_referrals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "affiliate_profile_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "status", default: 0
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_affiliate_referrals_on_account_id"
    t.index ["affiliate_profile_id"], name: "index_affiliate_referrals_on_affiliate_profile_id"
    t.index ["created_at"], name: "index_affiliate_referrals_on_created_at"
    t.index ["status"], name: "index_affiliate_referrals_on_status"
  end

  create_table "channel_apis", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "webhook_configurations", default: {}, null: false
    t.string "webhook_password"
    t.string "webhook_secret", null: false
    t.string "webhook_url"
    t.string "webhook_username"
    t.index ["account_id", "created_at"], name: "index_channel_apis_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_apis_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_apis_on_account_id"
    t.index ["status"], name: "index_channel_apis_on_status"
  end

  create_table "channel_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "email"
    t.string "forward_email"
    t.jsonb "imap_configurations", default: {}, null: false
    t.string "name"
    t.integer "service"
    t.jsonb "smtp_configurations", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_emails_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_emails_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_emails_on_account_id"
    t.index ["email"], name: "index_channel_emails_on_email", unique: true
    t.index ["forward_email"], name: "index_channel_emails_on_forward_email", unique: true
    t.index ["status"], name: "index_channel_emails_on_status"
  end

  create_table "channel_facebook_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token", null: false
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "instagram_identifier"
    t.string "name"
    t.string "page_identifier", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
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
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "line_identifier", null: false
    t.string "name"
    t.string "secret", null: false
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_lines_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_lines_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_lines_on_account_id"
    t.index ["line_identifier"], name: "index_channel_lines_on_line_identifier", unique: true
    t.index ["status"], name: "index_channel_lines_on_status"
  end

  create_table "channel_short_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "full_phone_number"
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.integer "service", default: 0, null: false
    t.string "service_identifier"
    t.integer "short_message_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_short_messages_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_short_messages_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_short_messages_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_short_messages_on_full_phone_number", unique: true
    t.index ["service", "service_identifier"], name: "index_channel_short_messages_on_service_and_service_identifier", unique: true
    t.index ["status"], name: "index_channel_short_messages_on_status"
  end

  create_table "channel_telegrams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name"
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_telegrams_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_telegrams_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_telegrams_on_account_id"
    t.index ["status"], name: "index_channel_telegrams_on_status"
    t.index ["token"], name: "index_channel_telegrams_on_token", unique: true
  end

  create_table "channel_twitter_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "handle_tweets", default: true, null: false
    t.string "name"
    t.string "profile_identifier", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "tokens", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_twitter_profiles_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_twitter_profiles_on_account_id_and_name"
    t.index ["account_id", "profile_identifier"], name: "idx_on_account_id_profile_identifier_4a1bc813e6", unique: true
    t.index ["account_id"], name: "index_channel_twitter_profiles_on_account_id"
    t.index ["profile_identifier"], name: "index_channel_twitter_profiles_on_profile_identifier"
    t.index ["status"], name: "index_channel_twitter_profiles_on_status"
  end

  create_table "channel_web_widgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "flags", default: 0, null: false
    t.string "name"
    t.uuid "portal_id"
    t.string "secret", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "ui_configurations", default: {}, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "website_url"
    t.index ["account_id", "created_at"], name: "index_channel_web_widgets_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_web_widgets_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_web_widgets_on_account_id"
    t.index ["portal_id"], name: "index_channel_web_widgets_on_portal_id"
    t.index ["status"], name: "index_channel_web_widgets_on_status"
    t.index ["website_url"], name: "index_channel_web_widgets_on_website_url"
  end

  create_table "channel_whatsapps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "api_key"
    t.string "business_account_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "full_phone_number", null: false
    t.string "name"
    t.string "phone_code"
    t.string "phone_number"
    t.string "phone_number_id"
    t.integer "service", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "webhook_secret"
    t.index ["account_id", "created_at"], name: "index_channel_whatsapps_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_whatsapps_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_whatsapps_on_account_id"
    t.index ["full_phone_number"], name: "index_channel_whatsapps_on_full_phone_number", unique: true
    t.index ["service"], name: "index_channel_whatsapps_on_service"
    t.index ["status"], name: "index_channel_whatsapps_on_status"
  end

  create_table "countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "iso", null: false
    t.string "iso3", null: false
    t.string "iso_name", null: false
    t.integer "numeric_code"
    t.boolean "states_required", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index "lower((iso_name)::text)", name: "index_countries_on_lower_iso_name", unique: true
    t.index ["created_at"], name: "index_countries_on_created_at"
    t.index ["iso"], name: "index_countries_on_iso", unique: true
    t.index ["iso3"], name: "index_countries_on_iso3", unique: true
  end

  create_table "country_translations", force: :cascade do |t|
    t.uuid "country_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.string "name"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["country_id", "locale"], name: "index_country_translations_on_country_id_and_locale", unique: true
    t.index ["country_id"], name: "index_country_translations_on_country_id"
    t.index ["locale"], name: "index_country_translations_on_locale"
    t.index ["name", "locale"], name: "index_country_translations_on_name_and_locale"
  end

  create_table "domains", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "configurations", default: {}, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "managed", default: false, null: false
    t.string "name", default: ""
    t.boolean "require_ssl", default: true, null: false
    t.datetime "ssl_added_at"
    t.integer "status", default: 0, null: false
    t.boolean "system_provided", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "value", null: false
    t.index ["account_id", "created_at"], name: "index_domains_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_domains_on_account_id"
    t.index ["managed"], name: "index_domains_on_managed"
    t.index ["status"], name: "index_domains_on_status"
    t.index ["system_provided"], name: "index_domains_on_system_provided"
    t.index ["value"], name: "index_domains_on_value", unique: true
  end

  create_table "exchange_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "from_currency", null: false
    t.decimal "rate", precision: 10, scale: 6, null: false
    t.string "to_currency", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_exchange_rates_on_created_at"
    t.index ["from_currency", "to_currency"], name: "index_exchange_rates_on_from_currency_and_to_currency", unique: true
  end

  create_table "global_routings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "route_type", null: false
    t.string "route_value", null: false
    t.string "shard_key", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_global_routings_on_account_id"
    t.index ["route_type", "route_value"], name: "index_global_routings_on_type_and_value", unique: true
  end

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "brand"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "expiry_month"
    t.integer "expiry_year"
    t.string "external_id"
    t.boolean "is_default", default: false, null: false
    t.string "last_four"
    t.integer "payment_type", default: 0, null: false
    t.integer "provider", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "is_default"], name: "index_payment_methods_on_account_id_and_is_default"
    t.index ["account_id"], name: "index_payment_methods_on_account_id"
    t.index ["external_id"], name: "index_payment_methods_on_external_id"
  end

  create_table "plan_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description"
    t.string "display_name", null: false
    t.string "locale", null: false
    t.uuid "plan_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["plan_id", "locale"], name: "index_plan_translations_on_plan_id_and_locale", unique: true
    t.index ["plan_id"], name: "index_plan_translations_on_plan_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "annual_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.jsonb "configurations", default: {}, null: false
    t.boolean "contact_us", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.jsonb "limits", default: {}, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "trial_days", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_plans_on_name", unique: true
    t.index ["position"], name: "index_plans_on_position"
    t.index ["status"], name: "index_plans_on_status"
  end

  create_table "state_translations", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "locale", null: false
    t.string "name"
    t.uuid "state_id", null: false
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

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "billing_cycle", default: 0, null: false
    t.datetime "cancelled_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.jsonb "data", default: {}, null: false
    t.string "external_id"
    t.uuid "plan_id", null: false
    t.integer "provider", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "trial_end_at"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "status"], name: "index_subscriptions_on_account_id_and_status"
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["current_period_end"], name: "index_subscriptions_on_current_period_end"
    t.index ["external_id"], name: "index_subscriptions_on_external_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["trial_end_at"], name: "index_subscriptions_on_trial_end_at"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "code", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.jsonb "data", default: {}, null: false
    t.string "description"
    t.string "external_id"
    t.integer "provider", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.uuid "subscription_id"
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["code"], name: "index_transactions_on_code", unique: true
    t.index ["created_at"], name: "index_transactions_on_created_at"
    t.index ["external_id"], name: "index_transactions_on_external_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["subscription_id"], name: "index_transactions_on_subscription_id"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "address_id"
    t.jsonb "configurations", default: {}, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.string "connection_token", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.jsonb "data", default: {}, null: false
    t.string "display_name"
    t.date "dob"
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.integer "gender", default: 0, null: false
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "locale", default: "en", null: false
    t.datetime "locked_at"
    t.string "middle_name"
    t.string "name", default: ""
    t.string "provider"
    t.string "provider_uid"
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

  create_table "wallet_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "balance_after", precision: 10, scale: 2, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.string "description"
    t.uuid "reference_id"
    t.string "reference_type"
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "wallet_id", null: false
    t.index ["account_id"], name: "index_wallet_transactions_on_account_id"
    t.index ["created_at"], name: "index_wallet_transactions_on_created_at"
    t.index ["reference_type", "reference_id"], name: "index_wallet_transactions_on_reference"
    t.index ["transaction_type"], name: "index_wallet_transactions_on_transaction_type"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_wallets_on_account_id", unique: true
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
  add_foreign_key "affiliate_commissions", "affiliate_commissions", column: "original_commission_id", on_delete: :nullify
  add_foreign_key "affiliate_commissions", "affiliate_profiles", on_delete: :cascade
  add_foreign_key "affiliate_commissions", "affiliate_referrals", on_delete: :cascade
  add_foreign_key "affiliate_commissions", "transactions", column: "transaction_record_id", on_delete: :cascade
  add_foreign_key "affiliate_payouts", "affiliate_profiles", on_delete: :cascade
  add_foreign_key "affiliate_profiles", "users", on_delete: :cascade
  add_foreign_key "affiliate_referrals", "accounts", on_delete: :cascade
  add_foreign_key "affiliate_referrals", "affiliate_profiles", on_delete: :cascade
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
  add_foreign_key "global_routings", "accounts", on_delete: :cascade
  add_foreign_key "payment_methods", "accounts", on_delete: :cascade
  add_foreign_key "plan_translations", "plans", on_delete: :cascade
  add_foreign_key "state_translations", "states", on_delete: :cascade
  add_foreign_key "states", "countries", on_delete: :cascade
  add_foreign_key "subscriptions", "accounts", on_delete: :cascade
  add_foreign_key "subscriptions", "plans", on_delete: :restrict
  add_foreign_key "transactions", "accounts", on_delete: :cascade
  add_foreign_key "transactions", "subscriptions", on_delete: :nullify
  add_foreign_key "users", "addresses", on_delete: :nullify
  add_foreign_key "wallet_transactions", "accounts", on_delete: :cascade
  add_foreign_key "wallet_transactions", "wallets", on_delete: :cascade
  add_foreign_key "wallets", "accounts", on_delete: :cascade
end
