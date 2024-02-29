class CreateChannelEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_emails, id: :uuid do |t|
      t.string  :name
      t.string  :email
      t.string  :forward_email
      t.jsonb   :imap_configurations, default: {}, null: false
      t.jsonb   :smtp_configurations, default: {}, null: false
      t.jsonb   :configurations, default: {}, null: false
      t.integer :service
      t.integer :status, default: Channel::Email.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps  default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
      t.index :email,         unique: true
      t.index :forward_email, unique: true
    end
  end
end
