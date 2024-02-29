class CreateIdentitySources < ActiveRecord::Migration[7.1]
  def change
    create_table :identity_sources, id: :uuid do |t|
      t.string  :name, null: false
      t.string  :source_url
      t.text    :description
      t.integer :source_type, null: false, default: IdentitySource.source_types[:api]

      t.jsonb :configurations,   null: false, default: {}
      t.jsonb :headers,          null: false, default: {}
      t.jsonb :response_mapping, null: false, default: {}
      t.jsonb :params,           null: false, default: {}

      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
