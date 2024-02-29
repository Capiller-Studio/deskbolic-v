class CreateHelpCenterCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_categories, id: :uuid do |t|
      t.integer :ancestry_depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0
      t.jsonb   :configurations, null: false, default: {}
      t.string  :permalink,  null: false
      t.string  :identifier, null: false
      t.boolean :hidden, null: false, default: false
      t.string  :code, null: false
      t.string  :ancestry
      t.integer :position

      t.integer :status,            null: false, default: HelpCenter::Portal.statuses[:active]
      t.integer :flags,             null: false, default: 0

      t.references :account, null: false, foreign_key: false,                                                 type: :uuid, index: true
      t.references :portal,  null: false, foreign_key: { to_table: :help_center_portals, on_delete: :cascade}, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :status]
      t.index [:portal_id, :ancestry]
      t.index [:portal_id, :hidden]
      t.index [:portal_id, :position]
      t.index [:portal_id, :permalink], unique: true
      t.index [:portal_id, :identifier], unique: true
      t.index [:portal_id, :flags]
      t.index [:portal_id, :created_at]
    end
  end
end
