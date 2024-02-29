class CreateEmailTemplateTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :email_template_translations do |t|
      t.string  :subject
      t.text    :body
      t.string  :locale, null: false

      t.references :email_template, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:subject, :locale]
      t.index [:email_template_id, :locale], unique: true
    end
  end
end
