class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.string   :email
      t.string   :username
      t.string   :first_name
      t.string   :middle_name
      t.string   :last_name
      t.string   :name, default: ""
      t.string   :display_name
      t.jsonb    :tokens,                default: {}, null: false
      t.jsonb    :configurations,        default: {}, null: false
      t.jsonb    :data,                  default: {}, null: false
      t.string   :locale,                null: false, default: "en"
      t.jsonb    :schedular_data,        null: false, default: {}
      t.string   :encrypted_password,    null: false, default: ""
      t.string   :external_id
      t.string   :identifier
      t.datetime :last_activity_at
      t.integer  :customer_type, null: false, default: Customer.customer_types[:guest]
      t.integer  :status, null: false, default: Customer.statuses[:active]

      t.integer  :sign_in_count,         null: false, default: 0
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at
      t.integer  :gender
      t.date     :dob

      t.string   :full_phone_number

      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :address, null: true,  foreign_key: false, type: :uuid, index: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
      t.index [:account_id, :locale]
      t.index [:account_id, :external_id]
      t.index [:account_id, :full_phone_number]
      t.index [:account_id, :email],                     unique: true
      t.index [:account_id, :username],                  unique: true
      t.index :reset_password_token,      unique: true
      t.index :confirmation_token,        unique: true
      t.index :unlock_token,              unique: true
    end
  end
end
