class CreateEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :email_templates, id: :uuid do |t|
      t.string :name

      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
    end
  end
end
