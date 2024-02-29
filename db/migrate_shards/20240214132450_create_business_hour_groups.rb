class CreateBusinessHourGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :business_hour_groups, id: :uuid do |t|
      t.string :name, null: false
      t.text   :description

      t.jsonb :configurations, null: false, default: {}

      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
