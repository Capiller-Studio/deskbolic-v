class CreateMacros < ActiveRecord::Migration[7.1]
  def change
    create_table :macros, id: :uuid do |t|
      t.string  :name
      t.integer :macro_type, null: false, default: Macro.macro_types[:manual]
      t.integer :status,     null: false, default: Macro.statuses[:active]
      t.jsonb   :events,     null: false, default: {}
      t.jsonb   :actions,    null: false, default: {}
      t.boolean :managed,    null: false, default: false

      t.references :account, null: false, foreign_key: false,  type: :uuid, index: true
      t.references :user,    null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :macro_type]
      t.index [:account_id, :status]
      t.index [:account_id, :managed]
      t.index [:account_id, :created_at]
    end
  end
end
