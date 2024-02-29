class CreateNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_settings, id: :uuid do |t|
      t.integer :email_flags,    null: false, default: 0
      t.integer :push_flags,     null: false, default: 0
      t.jsonb   :configurations, null: false, default: {}

      t.references :account,   null: false, foreign_key: false,    type: :uuid, index: true
      t.references :user,     null: false,  foreign_key: false,    type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
 
      t.index [:account_id, :user_id], unique: true
      t.index [:user_id, :created_at]
    end
  end
end
