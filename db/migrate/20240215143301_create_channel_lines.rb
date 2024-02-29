class CreateChannelLines < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_lines, id: :uuid do |t|
      t.string  :name
      t.string  :line_identifier, null: false
      t.string  :secret, null: false
      t.string  :token, null: false
      t.jsonb   :configurations, default: {}, null: false
      t.integer :status, default: Channel::Line.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :line_identifier, unique: true
      t.index [:account_id, :created_at]
    end
  end
end
