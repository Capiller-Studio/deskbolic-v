class CreatePropertyResources < ActiveRecord::Migration[7.1]
  def change
    create_table :property_resources, id: :uuid do |t|
      t.string    :value, array: true # TODO: WIP, mybe jsonb will be a good fit or perhaps different type specific models eg. one for string and one for datetime
      t.integer   :position


      t.references :resource, null: false, polymorphic: true,                    type: :uuid, index: true
      t.references :property, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:property_id, :value]
      t.index [:property_id, :resource_id], unique: true
      t.index [:resource_id, :created_at]
    end
  end
end
