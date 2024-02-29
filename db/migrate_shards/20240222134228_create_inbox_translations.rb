class CreateInboxTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_translations do |t|
      t.text    :greetings
      t.text    :notice
      t.text    :out_of_office_message
      t.string  :locale, null: false

      t.references :inbox, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:inbox_id, :locale], unique: true
    end
  end
end
