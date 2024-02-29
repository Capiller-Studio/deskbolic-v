class CreateCountryTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :country_translations do |t|
      t.string  :name
      t.string  :locale, null: false

      t.references :country, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:name, :locale]
      t.index [:country_id, :locale], unique: true
    end
  end
end
