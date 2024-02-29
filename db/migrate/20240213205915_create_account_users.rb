class CreateAccountUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :account_users, id: :uuid do |t|
      t.integer    :role,         null: false, default: AccountUser.roles[:agent]
      t.integer    :status,       null: false, default: AccountUser.statuses[:active]
      t.integer    :availability, null: false, default: AccountUser.availabilities[:offline]
      t.datetime   :status_changed_at
      t.datetime   :availability_changed_at
      t.datetime   :last_activity_at

      t.references :account,    null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :user,       null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :invited_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index :role
      t.index :created_at
      t.index :availability
      t.index [:account_id, :user_id], unique: true
    end
  end
end
