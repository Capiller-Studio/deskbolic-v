class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.integer  :event, null: false, default: Notification.events[:conversation_created]
      t.datetime :read_at

      t.references :account,   null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :user,     null: false, foreign_key: false,                     type: :uuid, index: true
      t.references :resource, null: false, polymorphic: true,                      type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:user_id, :event]
      t.index [:user_id, :created_at]
    end
  end
end
