class CreateChannelFacebookPages < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_facebook_pages, id: :uuid do |t|
      t.string  :page_identifier, null: false
      t.string  :instagram_identifier
      t.jsonb   :tokens, null: false, default: {}
      t.string  :name
      t.jsonb   :configurations, null: false, default: {}
      t.jsonb   :data,           null: false, default: {}
      t.integer :status, default: Channel::FacebookPage.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :page_identifier
      t.index [:account_id, :page_identifier], unique: true
      t.index :instagram_identifier
      t.index [:account_id, :created_at]
    end
  end
end
