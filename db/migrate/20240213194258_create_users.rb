class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string   :email, null: false
      t.string   :username
      t.string   :first_name
      t.string   :middle_name
      t.string   :last_name
      t.string   :name, default: ""
      t.string   :display_name
      t.jsonb    :tokens,            default: {}, null: false
      t.jsonb    :configurations,    default: {}, null: false
      t.jsonb    :data,              default: {}, null: false
      # t.text     :message_signature
      t.string   :locale,                null: false, default: "en"
      t.jsonb    :schedular_data,        null: false, default: {}
      t.string   :encrypted_password,    null: false, default: ""
      t.integer  :status,                null: false, default:  User.statuses[:active]


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
      t.integer  :gender,          null: false, default: User.genders[:male]
      t.date     :dob


      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      t.string :provider
      t.string :provider_uid

      t.string :connection_token, null: false

      t.references :address, null: true,  foreign_key: { on_delete: :nullify }, type: :uuid, index: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index :name
      t.index :created_at
      t.index :locale
      t.index :email,                     unique: true
      t.index :username,                  unique: true
      t.index :reset_password_token,      unique: true
      t.index :confirmation_token,        unique: true
      t.index :unlock_token,              unique: true
      t.index [:provider, :provider_uid], unique: true
      t.index :connection_token,          unique: true
    end
  end
end

