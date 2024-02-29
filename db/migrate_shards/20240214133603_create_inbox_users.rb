class CreateInboxUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_users, id: :uuid do |t|
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :user,  null: false, foreign_key: false,                   type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:inbox_id, :user_id], unique: true
      t.index :created_at
    end
  end
end
