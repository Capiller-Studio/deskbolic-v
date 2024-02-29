class CreateBusinessHourTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :business_hour_translations do |t|
      t.text    :reason
      t.string  :locale, null: false

      t.references :business_hour, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:business_hour_id, :locale], unique: true
    end
  end
end
