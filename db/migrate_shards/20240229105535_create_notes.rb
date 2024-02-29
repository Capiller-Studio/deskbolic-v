class CreateNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :notes, id: :uuid do |t|
      t.string  :title
      t.text    :content
      t.integer :visibility, null: false, default: Note.visibilities[:personal]
      
      t.references :resource, null: true,  polymorphic: true,  type: :uuid, index: true
      t.references :user,     null: false, foreign_key: false, type: :uuid, index: true
      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :title]
      t.index [:account_id, :created_at]
    end
  end
end