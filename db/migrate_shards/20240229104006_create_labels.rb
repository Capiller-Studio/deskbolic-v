class CreateLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :labels, id: :uuid do |t|
      t.string  :title
      t.string  :identifier, null: false
      t.text    :description
      t.string  :color
      t.jsonb   :configurations, null: false, default: {}
      t.integer :flags,          null: false, default: 0

      t.references :account,         null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :title]
      t.index [:account_id, :identifier], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
