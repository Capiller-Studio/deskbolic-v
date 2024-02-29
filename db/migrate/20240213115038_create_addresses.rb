class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.string :name
      t.string :title
      t.string :address1
      t.string :address2
      t.string :city,    limit: 60
      t.string :zipcode, limit: 15
      t.string :phone_code
      t.string :phone_number
      t.string :alternative_phone_code
      t.string :alternative_phone_number
      t.string :state_name
      t.string :organization_name
      t.string :national_id
      t.text   :description
      t.string :designation

      t.references :state,   null: true, type: :uuid,   foreign_key: { on_delete: :nullify }, index: true
      t.references :country, null: true, type: :uuid,   foreign_key: { on_delete: :nullify }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :name
      t.index :organization_name
      t.index :created_at
    end
  end
end
