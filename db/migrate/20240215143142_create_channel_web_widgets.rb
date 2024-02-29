class CreateChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_web_widgets, id: :uuid do |t|
      t.string  :name
      t.string  :website_url
      t.jsonb   :configurations, default: {}, null: false
      t.jsonb   :ui_configurations, default: {}, null: false
      t.jsonb   :data, default: {}, null: false
      t.string  :secret, null: false
      t.integer :flags, default: 0, null: false
      t.integer :status, default: Channel::WebWidget.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :website_url
      t.index [:account_id, :created_at]
    end
  end
end
