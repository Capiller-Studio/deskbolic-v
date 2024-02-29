class CreateCannedResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :canned_responses, id: :uuid do |t|
      t.string :name
      t.text   :description
      t.string :identifier, null: false

      t.integer :status, null: false, default: CannedResponse.statuses[:active]

      t.references :account, null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :name]
      t.index [:account_id, :identifier], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
