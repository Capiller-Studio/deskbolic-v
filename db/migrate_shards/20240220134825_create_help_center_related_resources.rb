class CreateHelpCenterRelatedResources < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_related_resources, id: :uuid do |t|
      t.references :resource,        polymorphic: true, null: false, type: :uuid
      t.references :linked_resource, polymorphic: true, null: false, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:resource_id, :resource_type, :linked_resource_id, :linked_resource_type], unique: true, name: "index_help_center_related_resources_on_unique_record"
    end
  end
end
