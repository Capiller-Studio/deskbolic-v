class CreateAttachmentTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :attachment_translations do |t|
      t.string  :alt_title
      t.string  :locale, null: false

      t.references :attachment, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:attachment_id, :locale], unique: true
    end
  end
end
