class CreateChannelWhatsapps < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_whatsapps, id: :uuid do |t|
      t.string  :name
      t.string  :phone_code
      t.string  :phone_number
      t.string  :full_phone_number, null: false
      t.jsonb   :configurations, default: {}, null: false
      t.jsonb   :data, default: {}, null: false
      t.integer :service
      t.integer :status, default: Channel::Whatsapp.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :full_phone_number, unique: true
      t.index :service
      t.index [:account_id, :created_at]
    end
  end
end
