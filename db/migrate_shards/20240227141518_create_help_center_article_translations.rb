class CreateHelpCenterArticleTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_article_translations do |t|
      t.string  :title
      t.text    :meta_title
      t.text    :content
      t.text    :meta_description
      t.string  :meta_keywords, array: true, default: [], null: false
      t.string  :locale, null: false

      t.references :article, null: false, type: :uuid, foreign_key: { to_table: :help_center_articles, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:title, :locale]
      t.index [:article_id, :locale], unique: true
    end
  end
end
