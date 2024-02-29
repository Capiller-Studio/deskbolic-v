class CreateAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments, id: :uuid do |t|
      t.integer :attachment_type, null: false, default: Attachment.attachment_types[:image]
      t.string  :remote_url
      t.float   :latitude
      t.float   :longitude
      t.string  :extension

      t.references :resource, polymorphic: true, null: false,  type: :uuid, index: true
      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :attachment_type]
    end
  end
end
