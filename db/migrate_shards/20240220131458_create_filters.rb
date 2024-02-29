class CreateFilters < ActiveRecord::Migration[7.1]
  def change
    create_table :filters, id: :uuid do |t|
      t.string     :name
      t.integer    :filter_type, null: false, default: Filter.filter_types[:conversation]
      t.jsonb      :conditions, default: {}, null: false
      t.text       :description

      t.references :account, null: false, foreign_key: false,  type: :uuid, index: true
      t.references :user,    null: false, foreign_key: false,  type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :filter_type]
      t.index [:account_id, :created_at]
    end
  end
end
