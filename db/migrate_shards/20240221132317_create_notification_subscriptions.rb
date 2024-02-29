class CreateNotificationSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_subscriptions, id: :uuid do |t|
      t.string  :name
      t.integer :subscription_type, null: false, default: NotificationSubscription.subscription_types[:push]
      t.jsonb   :configurations, null: false, default: {}
      t.jsonb   :data, null: false, default: {}

      t.references :user,   null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
 
      t.index [:user_id, :subscription_type]
      t.index [:user_id, :created_at]
    end
  end
end
