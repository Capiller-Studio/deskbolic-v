class CreateCustomerInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_inboxes, id: :uuid do |t|
      t.string :external_id, null: false

      t.string :connection_token, null: false

      t.references :customer, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :inbox,    null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:customer_id, :inbox_id], unique: true
      t.index :connection_token,         unique: true
      t.index :external_id
    end
  end
end
