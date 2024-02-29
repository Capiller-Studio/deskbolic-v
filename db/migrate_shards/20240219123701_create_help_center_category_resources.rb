class CreateHelpCenterCategoryResources < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_category_resources, id: :uuid do |t|
      t.references :category, null: false, foreign_key: { to_table: :help_center_categories, on_delete: :cascade }, type: :uuid, index: true
      t.references :resource, polymorphic: true, null: false, type: :uuid, index: true
      t.integer    :position, default: 0, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index :position
      t.index [:category_id, :resource_id, :resource_type], unique: true
    end
  end
end
