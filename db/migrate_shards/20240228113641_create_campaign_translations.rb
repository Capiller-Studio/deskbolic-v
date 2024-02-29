class CreateCampaignTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_translations do |t|
      t.text    :content
      t.text    :plain_content
      t.string  :locale, null: false

      t.references :campaign, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:campaign_id, :locale], unique: true
    end
  end
end
