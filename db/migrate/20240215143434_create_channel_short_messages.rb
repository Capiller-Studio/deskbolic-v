class CreateChannelShortMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_short_messages, id: :uuid do |t|
      t.string  :name
      t.string  :phone_code
      t.string  :phone_number
      t.string  :full_phone_number
      t.jsonb   :tokens, default: {}, null: false
      t.jsonb   :configurations, default: {}, null: false
      t.jsonb   :data, default: {}, null: false
      t.string  :service_identifier
      t.integer :short_message_type,  default: Channel::ShortMessage.short_message_types[:sms], null: false
      t.integer :service,             default: Channel::ShortMessage.services[:twilio],         null: false
      t.integer :status,              default: Channel::Line.statuses[:active],                 null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :full_phone_number, unique: true
      t.index [:service, :service_identifier], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
