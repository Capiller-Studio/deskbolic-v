class CreateCountries < ActiveRecord::Migration[7.1]
  def change
    create_table :countries, id: :uuid do |t|
      t.string   :iso,               null: false
      t.string   :iso3,              null: false
      t.string   :iso_name,          null: false
      t.boolean  :states_required,   null: false, default: false
      t.integer  :numeric_code

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :iso, unique: true
      t.index :iso3, unique: true
      t.index "lower((iso_name)::text)", name: "index_countries_on_lower_iso_name", unique: true
      t.index :created_at
    end
  end
end
