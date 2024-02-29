class CreateHelpCenterArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_articles, id: :uuid do |t|
      t.integer :views_count, null: false, default: 0
      t.string  :slug, null: false
      # t.string  :identifier, null: false
      t.jsonb   :configurations, null: false, default: {}
      t.integer :position

      t.integer :status,            null: false, default: HelpCenter::Article.statuses[:active]
      t.integer :flags,             null: false, default: 0

      t.references :account, null: false, foreign_key: false,                                                   type: :uuid, index: true
      t.references :portal,  null: false, foreign_key: { to_table: :help_center_portals, on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :status]
      t.index [:portal_id, :position]
      t.index [:portal_id, :slug], unique: true
      # t.index [:portal_id, :identifier], unique: true
      t.index [:portal_id, :flags]
      t.index [:portal_id, :created_at]
    end
  end
end
