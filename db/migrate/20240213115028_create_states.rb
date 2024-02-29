class CreateStates < ActiveRecord::Migration[7.1]
  def change
    create_table :states, id: :uuid do |t|
      t.string :abbr

      t.references :country, null: false, type: :uuid, foreign_key: { on_delete: :cascade }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :abbr
      t.index :created_at
    end
  end
end
