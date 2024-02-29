class CreateHelpCenterCategoryTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_category_translations do |t|
      t.string  :name
      t.text    :meta_title
      t.text    :description
      t.text    :meta_description
      t.string  :meta_keywords, array: true, default: [], null: false
      t.string  :locale, null: false

      t.references :category, null: false, type: :uuid, foreign_key: { to_table: :help_center_categories, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:name, :locale]
      t.index [:category_id, :locale], unique: true
    end
  end
end
