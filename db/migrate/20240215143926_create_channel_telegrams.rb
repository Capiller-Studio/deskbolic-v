class CreateChannelTelegrams < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_telegrams, id: :uuid do |t|
      t.string  :name
      t.string  :token,   null: false
      t.jsonb   :configurations, default: {}, null: false
      t.integer :status,  default: Channel::Telegram.statuses[:active],         null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :token, unique: true
      t.index [:account_id, :created_at]
    end
  end
end
