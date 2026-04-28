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

ActiveRecord::Schema[8.0].define(version: 2026_04_22_000011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "access_account_user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "account_user_id", null: false
    t.uuid "role_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_access_account_user_roles_on_account_id"
    t.index ["account_user_id", "role_id"], name: "idx_acc_user_role_composite"
    t.index ["created_at"], name: "index_access_account_user_roles_on_created_at"
    t.index ["role_id"], name: "index_access_account_user_roles_on_role_id"
  end

  create_table "access_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.boolean "is_system", default: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_access_roles_on_account_id_and_name"
    t.index ["account_id"], name: "index_access_roles_on_account_id"
    t.index ["created_at"], name: "index_access_roles_on_created_at"
  end

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
    t.string "currency", limit: 4, default: "USD", null: false
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

  create_table "affiliate_commissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_profile_id", null: false
    t.uuid "affiliate_referral_id", null: false
    t.uuid "transaction_record_id", null: false
    t.uuid "original_commission_id"
    t.decimal "original_amount", precision: 10, scale: 2, null: false
    t.string "original_currency", null: false
    t.decimal "exchange_rate", precision: 10, scale: 6, default: "1.0"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "commission_type", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
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
    t.integer "status", default: 0
    t.jsonb "data", default: {}
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["affiliate_profile_id"], name: "index_affiliate_payouts_on_affiliate_profile_id"
    t.index ["created_at"], name: "index_affiliate_payouts_on_created_at"
    t.index ["status"], name: "index_affiliate_payouts_on_status"
  end

  create_table "affiliate_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "referral_code", null: false
    t.decimal "commission_rate", precision: 5, scale: 2
    t.integer "tenure_months"
    t.decimal "max_earnings_per_account", precision: 10, scale: 2
    t.integer "holding_days"
    t.string "currency", default: "USD", null: false
    t.jsonb "bank_account_data", default: {}
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_affiliate_profiles_on_created_at"
    t.index ["currency"], name: "index_affiliate_profiles_on_currency"
    t.index ["referral_code"], name: "index_affiliate_profiles_on_referral_code", unique: true
    t.index ["user_id"], name: "index_affiliate_profiles_on_user_id"
  end

  create_table "affiliate_referrals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_profile_id", null: false
    t.uuid "account_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_affiliate_referrals_on_account_id"
    t.index ["affiliate_profile_id"], name: "index_affiliate_referrals_on_affiliate_profile_id"
    t.index ["created_at"], name: "index_affiliate_referrals_on_created_at"
    t.index ["status"], name: "index_affiliate_referrals_on_status"
  end

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
    t.jsonb "data", default: {}, null: false
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
    t.uuid "portal_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "created_at"], name: "index_channel_web_widgets_on_account_id_and_created_at"
    t.index ["account_id", "name"], name: "index_channel_web_widgets_on_account_id_and_name"
    t.index ["account_id"], name: "index_channel_web_widgets_on_account_id"
    t.index ["portal_id"], name: "index_channel_web_widgets_on_portal_id"
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
    t.integer "service", default: 0, null: false
    t.string "webhook_secret"
    t.string "api_key"
    t.string "phone_number_id"
    t.string "business_account_id"
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
    t.integer "role", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.string "member_type", null: false
    t.uuid "member_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_conversation_members_on_account_id"
    t.index ["conversation_id", "member_id"], name: "index_conversation_members_on_conversation_id_and_member_id", unique: true
    t.index ["conversation_id", "role"], name: "index_conversation_members_on_conversation_id_and_role"
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

  create_table "email_template_layout_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.string "locale", null: false
    t.uuid "email_template_layout_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email_template_layout_id", "locale"], name: "idx_email_layout_translations_on_layout_id_and_locale", unique: true
    t.index ["email_template_layout_id"], name: "idx_on_email_template_layout_id_412d4e8613"
    t.index ["locale"], name: "index_email_template_layout_translations_on_locale"
  end

  create_table "email_template_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "name"], name: "index_email_template_layouts_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_template_layouts_on_account_id"
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

  create_table "exchange_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "from_currency", null: false
    t.string "to_currency", null: false
    t.decimal "rate", precision: 10, scale: 6, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_exchange_rates_on_created_at"
    t.index ["from_currency", "to_currency"], name: "index_exchange_rates_on_from_currency_and_to_currency", unique: true
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
    t.jsonb "custom_attributes", default: {}, null: false
    t.jsonb "raw_response", default: {}, null: false
    t.integer "identity_type", default: 0, null: false
    t.uuid "account_id", null: false
    t.uuid "address_id"
    t.uuid "customer_id", null: false
    t.uuid "identity_source_id"
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

  create_table "integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "provider", null: false
    t.jsonb "settings", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "provider"], name: "index_integrations_on_account_id_and_provider", unique: true
    t.index ["account_id"], name: "index_integrations_on_account_id"
    t.index ["created_at"], name: "index_integrations_on_created_at"
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
    t.string "external_reply_to_id"
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

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "provider", default: 0, null: false
    t.integer "payment_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.boolean "is_default", default: false, null: false
    t.string "last_four"
    t.string "brand"
    t.integer "expiry_month"
    t.integer "expiry_year"
    t.string "external_id"
    t.jsonb "data", default: {}, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "is_default"], name: "index_payment_methods_on_account_id_and_is_default"
    t.index ["account_id"], name: "index_payment_methods_on_account_id"
    t.index ["external_id"], name: "index_payment_methods_on_external_id"
  end

  create_table "plan_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "locale", null: false
    t.string "display_name", null: false
    t.text "description"
    t.uuid "plan_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["plan_id", "locale"], name: "index_plan_translations_on_plan_id_and_locale", unique: true
    t.index ["plan_id"], name: "index_plan_translations_on_plan_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "annual_price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.jsonb "configurations", default: {}, null: false
    t.jsonb "limits", default: {}, null: false
    t.integer "trial_days", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.boolean "contact_us", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_plans_on_name", unique: true
    t.index ["position"], name: "index_plans_on_position"
    t.index ["status"], name: "index_plans_on_status"
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

  create_table "sla_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "sla_policy_id", null: false
    t.uuid "inbox_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_sla_inboxes_on_account_id"
    t.index ["inbox_id"], name: "index_sla_inboxes_on_inbox_id"
    t.index ["sla_policy_id", "inbox_id"], name: "index_sla_inboxes_on_sla_policy_id_and_inbox_id", unique: true
    t.index ["sla_policy_id"], name: "index_sla_inboxes_on_sla_policy_id"
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

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.integer "billing_cycle", default: 0, null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "trial_end_at"
    t.datetime "cancelled_at"
    t.string "external_id"
    t.integer "provider", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "plan_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "status"], name: "index_subscriptions_on_account_id_and_status"
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["current_period_end"], name: "index_subscriptions_on_current_period_end"
    t.index ["external_id"], name: "index_subscriptions_on_external_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["trial_end_at"], name: "index_subscriptions_on_trial_end_at"
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

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.integer "transaction_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.integer "provider", default: 0, null: false
    t.string "external_id"
    t.string "description"
    t.jsonb "data", default: {}, null: false
    t.uuid "account_id", null: false
    t.uuid "subscription_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
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

  create_table "wallet_transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "transaction_type", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "balance_after", precision: 10, scale: 2, null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.string "description"
    t.uuid "account_id", null: false
    t.uuid "wallet_id", null: false
    t.string "reference_type"
    t.uuid "reference_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_wallet_transactions_on_account_id"
    t.index ["created_at"], name: "index_wallet_transactions_on_created_at"
    t.index ["reference_type", "reference_id"], name: "index_wallet_transactions_on_reference"
    t.index ["transaction_type"], name: "index_wallet_transactions_on_transaction_type"
    t.index ["wallet_id"], name: "index_wallet_transactions_on_wallet_id"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", limit: 4, default: "USD", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_wallets_on_account_id", unique: true
  end

  create_table "webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_id", null: false
    t.string "event_name", null: false
    t.string "endpoint_url", null: false
    t.jsonb "request_payload", default: {}
    t.integer "status", default: 0
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_webhook_deliveries_on_created_at"
    t.index ["event_name"], name: "index_webhook_deliveries_on_event_name"
    t.index ["integration_id"], name: "index_webhook_deliveries_on_integration_id"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
  end

  create_table "webhook_delivery_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "webhook_delivery_id", null: false
    t.integer "attempt_number", default: 1, null: false
    t.integer "http_status"
    t.text "response_body"
    t.text "error_trace"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_webhook_delivery_attempts_on_created_at"
    t.index ["webhook_delivery_id"], name: "index_webhook_delivery_attempts_on_webhook_delivery_id"
  end

  add_foreign_key "access_account_user_roles", "access_roles", column: "role_id", on_delete: :cascade
  add_foreign_key "access_account_user_roles", "accounts", on_delete: :cascade
  add_foreign_key "access_roles", "accounts", on_delete: :cascade
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
  add_foreign_key "attachment_translations", "attachments", on_delete: :cascade
  add_foreign_key "business_hour_translations", "business_hours", on_delete: :cascade
  add_foreign_key "business_hours", "business_hour_groups", on_delete: :cascade
  add_foreign_key "campaign_translations", "campaigns", on_delete: :cascade
  add_foreign_key "campaigns", "email_templates", on_delete: :nullify
  add_foreign_key "canned_response_translations", "canned_responses", on_delete: :cascade
  add_foreign_key "channel_apis", "accounts", on_delete: :cascade
  add_foreign_key "channel_emails", "accounts", on_delete: :cascade
  add_foreign_key "channel_facebook_pages", "accounts", on_delete: :cascade
  add_foreign_key "channel_lines", "accounts", on_delete: :cascade
  add_foreign_key "channel_short_messages", "accounts", on_delete: :cascade
  add_foreign_key "channel_telegrams", "accounts", on_delete: :cascade
  add_foreign_key "channel_twitter_profiles", "accounts", on_delete: :cascade
  add_foreign_key "channel_web_widgets", "accounts", on_delete: :cascade
  add_foreign_key "channel_whatsapps", "accounts", on_delete: :cascade
  add_foreign_key "chat_bot_inboxes", "chat_bots", on_delete: :cascade
  add_foreign_key "chat_bot_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "conversation_members", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "conversations", on_delete: :cascade
  add_foreign_key "conversation_slas", "sla_policies", on_delete: :cascade
  add_foreign_key "conversations", "campaigns", on_delete: :nullify
  add_foreign_key "conversations", "inboxes", on_delete: :cascade
  add_foreign_key "country_translations", "countries", on_delete: :cascade
  add_foreign_key "customer_inboxes", "customers", on_delete: :cascade
  add_foreign_key "customer_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "domains", "accounts", on_delete: :cascade
  add_foreign_key "email_template_layout_translations", "email_template_layouts", on_delete: :cascade
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
  add_foreign_key "integrations", "accounts", on_delete: :cascade
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "inboxes", on_delete: :cascade
  add_foreign_key "payment_methods", "accounts", on_delete: :cascade
  add_foreign_key "plan_translations", "plans", on_delete: :cascade
  add_foreign_key "property_resources", "properties", on_delete: :cascade
  add_foreign_key "sla_inboxes", "inboxes", on_delete: :cascade
  add_foreign_key "sla_inboxes", "sla_policies", on_delete: :cascade
  add_foreign_key "state_translations", "states", on_delete: :cascade
  add_foreign_key "states", "countries", on_delete: :cascade
  add_foreign_key "subscriptions", "accounts", on_delete: :cascade
  add_foreign_key "subscriptions", "plans", on_delete: :restrict
  add_foreign_key "team_users", "teams", on_delete: :cascade
  add_foreign_key "transactions", "accounts", on_delete: :cascade
  add_foreign_key "transactions", "subscriptions", on_delete: :nullify
  add_foreign_key "users", "addresses", on_delete: :nullify
  add_foreign_key "wallet_transactions", "accounts", on_delete: :cascade
  add_foreign_key "wallet_transactions", "wallets", on_delete: :cascade
  add_foreign_key "wallets", "accounts", on_delete: :cascade
  add_foreign_key "webhook_deliveries", "integrations", on_delete: :cascade
  add_foreign_key "webhook_delivery_attempts", "webhook_deliveries", on_delete: :cascade
end
