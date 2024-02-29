class CreateConversationSlas < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_slas, id: :uuid do |t|
      t.integer    :status, null: false, default: ConversationSla.statuses[:pending]

      t.references :account,         null: false, foreign_key: false,                     type: :uuid, index: true
      t.references :sla_policy,      null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true
      t.references :conversation,    null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:conversation_id, :sla_policy_id], unique: true
      t.index [:account_id, :status]
      t.index [:account_id, :created_at]
    end
  end
end
