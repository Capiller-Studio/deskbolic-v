class CreateCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :campaigns, id: :uuid do |t|
      t.string   :name
      t.text     :description
      t.integer  :status,        null: false, default: Campaign.statuses[:active]
      t.integer  :campaign_type, null: false, default: Campaign.campaign_types[:one_time]
      t.datetime :start_at
      t.datetime :end_at
      t.jsonb    :conditions, null: false, default: {}

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :user,           null: true,  foreign_key: false,                    type: :uuid, index: false
      t.references :email_template, null: true,  foreign_key: { on_delete: :nullify },  type: :uuid, index: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :campaign_type]
      t.index [:account_id, :status]
      t.index [:account_id, :start_at]
      t.index [:account_id, :created_at]
    end
  end
end
