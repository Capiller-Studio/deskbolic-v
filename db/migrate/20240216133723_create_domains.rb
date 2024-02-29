class CreateDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :domains, id: :uuid do |t|
      t.string   :name, default: ""
      t.string   :value, null: false
      t.datetime :ssl_added_at
      t.integer  :status,           null: false, default: Domain.statuses[:active]
      t.jsonb    :configurations,   null: false, default: {}
      t.boolean  :managed,          null: false, default: false
      t.boolean  :system_provided,  null: false, default: false
      t.boolean  :require_ssl,      null: false, default: true

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :value, unique: true
      t.index :status
      t.index :managed
      t.index :system_provided
      t.index [:account_id, :created_at]
    end
  end
end
