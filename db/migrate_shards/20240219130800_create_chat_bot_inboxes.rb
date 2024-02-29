class CreateChatBotInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_bot_inboxes, id: :uuid do |t|
      t.references :chat_bot, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :inbox,    null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      
      t.integer :status, null: false, default: ChatBotInbox.statuses[:active]

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:chat_bot_id, :inbox_id], unique: true
      t.index [:chat_bot_id, :inbox_id, :status]
      t.index :created_at
    end
  end
end
