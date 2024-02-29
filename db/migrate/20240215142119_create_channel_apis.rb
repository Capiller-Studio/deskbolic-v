class CreateChannelApis < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_apis, id: :uuid do |t|
      t.string  :webhook_url
      t.string  :webhook_username
      t.string  :webhook_password
      t.string  :webhook_secret, null: false
      t.string  :name
      t.jsonb   :configurations,         default: {}, null: false
      t.jsonb   :data,                   default: {}, null: false
      t.jsonb   :webhook_configurations, default: {}, null: false
      t.integer :status, default: Channel::Api.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps  default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
