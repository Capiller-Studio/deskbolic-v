class CreateChannelTwitterProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_twitter_profiles, id: :uuid do |t|
      t.string     :name
      t.string     :profile_identifier, null: false
      t.jsonb      :tokens, default: {}, null: false
      t.boolean    :handle_tweets, null: false, default: true
      t.integer    :status, default: Channel::TwitterProfile.statuses[:active], null: false

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :profile_identifier
      t.index [:account_id, :profile_identifier], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
