class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string   :name, null: false
      t.string   :locale, null: false, default: "en"
      t.string   :email
      t.bigint   :features,       default: 0, null: false
      t.jsonb    :limits,         default: {}, null: false
      t.jsonb    :data,           default: {}, null: false
      t.jsonb    :configurations, default: {}, null: false
      t.jsonb    :billing_data,   default: {}, null: false
      t.integer  :status, null: false, default: Account.statuses[:active]
      t.integer  :referral_commission_type, null: false, default: Account.referral_commission_types[:fixed]
      t.decimal  :referral_commission, precision: 10, scale: 2
      t.decimal  :referred_by_commission, precision: 10, scale: 2
      t.datetime :referral_approved_at
      t.datetime :referral_paid_at
      t.string   :identifier,    null: false
      t.string   :referral_code, null: false

      t.references :address, null: true, type: :uuid, foreign_key: { on_delete: :nullify }, index: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index :identifier, unique: true
      t.index :name
      t.index :created_at
      t.index :referral_code, unique: true
    end

    add_reference :accounts, :referred_by, null: true, type: :uuid, foreign_key: { on_delete: :nullify, to_table: :accounts }, index: true
  end
end
