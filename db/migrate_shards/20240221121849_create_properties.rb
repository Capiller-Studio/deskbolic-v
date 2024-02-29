class CreateProperties < ActiveRecord::Migration[7.1]
  def change
    create_table :properties, id: :uuid do |t|
      t.string  :name, null: false
      t.string  :display_name
      t.text    :description
      t.integer :display_type, null: false, default: Property.display_types[:text]
      t.integer :value_type,   null: false, default: Property.value_types[:string]
      t.jsonb   :conditions,   null: false, default: {} # { values: ['a', 'b'], pattern: "\abc\", multiple: false, min_value: 100 }

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
