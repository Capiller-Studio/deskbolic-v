class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.text    :content
      t.string  :external_id
      # t.boolean :private TODO: WIP

      # t.integer :message_type, null: false, default: Message.message_types[] TODO: WIP
      t.integer :status,       null: false, default: Message.statuses[:sent]
      t.integer :content_type, null: false, default: Message.content_types[:text]
      t.integer :visibility,   null: false, default: Message.visibilities[:global]

      t.jsonb  :configurations, default: {}, null: false
      t.jsonb  :data,           default: {}, null: false
      t.jsonb  :sentiment,      default: {}, null: false
      t.string :locale

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :inbox,          null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :conversation,   null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :sender,         null: false, polymorphic: true,                     type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :external_id]
      t.index [:conversation_id, :status]
      t.index [:conversation_id, :content_type]
      t.index [:conversation_id, :created_at]
    end
  end
end
