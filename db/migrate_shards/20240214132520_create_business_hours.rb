class CreateBusinessHours < ActiveRecord::Migration[7.1]
  def change
    create_table :business_hours, id: :uuid do |t|
      t.integer   :day_of_week
      t.time      :opening_time
      t.time      :closing_time
      t.datetime  :close_from
      t.datetime  :close_till

      t.jsonb :configurations, null: false, default: {}

      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true
      t.references :business_hour_group, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:business_hour_group_id, :day_of_week, :opening_time, :closing_time], name: "index_business_hours_on_work_time"
      t.index [:business_hour_group_id, :close_from, :close_till], name: "index_business_hours_on_close_time"
      t.index [:business_hour_group_id, :created_at]
    end
  end
end
