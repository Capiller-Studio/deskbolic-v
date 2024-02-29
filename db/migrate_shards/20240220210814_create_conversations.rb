class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations, id: :uuid do |t|
      t.string   :title
      t.jsonb    :configurations, null: false, default: {}
      t.jsonb    :data, null: false, default: {}
      t.string   :identifier, null: false
      t.integer  :status,   null: false, default: Conversation.statuses[:active]
      t.integer  :priority, null: false, default: Conversation.priorities[:low]
      t.datetime :status_changed_at
      t.datetime :last_activity_at
      t.datetime :first_respond_at
      t.string   :locale #, null: false, default: "en"

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :inbox,          null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :campaign,       null: true,  foreign_key: { on_delete: :nullify },  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :title]
      t.index [:account_id, :status]
      t.index [:account_id, :priority]
      t.index [:account_id, :identifier]
      t.index [:account_id, :last_activity_at]
      t.index [:account_id, :created_at]
    end
  end
end
