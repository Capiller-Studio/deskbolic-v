class CreateChatBots < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_bots, id: :uuid do |t|
      t.string   :name
      t.string   :display_name
      t.text     :description
      t.string   :identifier, null: false
      t.integer  :bot_type, null: false, default: ChatBot.bot_types[:api]
      t.string   :api_url
      t.jsonb    :configurations, default: {}, null: false

      t.integer :status,            null: false, default: ChatBot.statuses[:active]
      t.integer :flags,             null: false, default: 0

      t.references :account, null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :name]
      t.index [:account_id, :identifier], unique: true
      t.index [:account_id, :bot_type]
      t.index [:account_id, :flags]
      t.index [:account_id, :created_at]
    end
  end
end
