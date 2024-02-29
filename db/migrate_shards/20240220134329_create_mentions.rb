class CreateMentions < ActiveRecord::Migration[7.1]
  def change
    create_table :mentions, id: :uuid do |t|
      t.references :account,   null: false, foreign_key: false,  type: :uuid, index: true
      t.references :resource,  polymorphic: true, null: false,   type: :uuid, index: true
      t.references :mentioned, polymorphic: true, null: false,   type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:resource_id, :resource_type, :mentioned_id, :mentioned_type], unique: true, name: "index_mentions_on_unique_record"
    end
  end
end
