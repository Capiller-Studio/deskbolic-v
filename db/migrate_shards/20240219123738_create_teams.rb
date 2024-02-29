class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams, id: :uuid do |t|
      t.string  :name, null: false
      t.text    :description
      t.string  :identifier,  null: false
      t.boolean :auto_assign, null: false, default: true

      t.integer :status,            null: false, default: Team.statuses[:active]
      t.integer :flags,             null: false, default: 0

      t.references :account, null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :name]
      t.index [:account_id, :identifier], unique: true
      t.index [:account_id, :flags]
      t.index [:account_id, :created_at]
    end
  end
end
