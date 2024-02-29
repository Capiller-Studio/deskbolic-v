class CreateCannedResponseTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :canned_response_translations do |t|
      t.string  :content
      t.string  :locale, null: false

      t.references :canned_response, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:canned_response_id, :locale], unique: true
    end
  end
end
