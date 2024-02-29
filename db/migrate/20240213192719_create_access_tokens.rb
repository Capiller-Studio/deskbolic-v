class CreateAccessTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :access_tokens, id: :uuid do |t|
      t.string   :token,             null: false
      t.integer  :flags,             null: false, default: 0
      t.boolean  :destroy_after_use, null: false, default: false
      t.datetime :valid_till

      t.references :owner, polymorphic: true, null: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :token, unique: true
      t.index :created_at
    end
  end
end
