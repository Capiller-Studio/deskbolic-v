class CreateSlaPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :sla_policies, id: :uuid do |t|
      t.string  :name, null: false
      t.float   :response_time_limit
      t.float   :initial_response_time_limit
      t.float   :resolution_time_limit
      t.text    :description
      t.jsonb   :configurations, null: false, default: {}
      t.boolean :during_working_hours, null: false, default: false

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
