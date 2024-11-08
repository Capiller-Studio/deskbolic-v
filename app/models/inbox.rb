# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                     :uuid             not null, primary key
#  channel_type           :string           not null
#  configurations         :jsonb            not null
#  default_locale         :string           default("en"), not null
#  display_name           :string
#  flags                  :integer          default(0), not null
#  name                   :string           default(""), not null
#  status                 :integer          default("active"), not null
#  timezone               :string           default("UTC"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  business_hour_group_id :uuid
#  channel_id             :uuid             not null
#
# Indexes
#
#  index_inboxes_on_account_id                 (account_id)
#  index_inboxes_on_account_id_and_created_at  (account_id,created_at)
#  index_inboxes_on_account_id_and_name        (account_id,name)
#  index_inboxes_on_account_id_and_status      (account_id,status)
#  index_inboxes_on_business_hour_group_id     (business_hour_group_id)
#  index_inboxes_on_channel                    (channel_type,channel_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => nullify
#
class Inbox < ShardRecord
  belongs_to :channel, polymorphic: true
  belongs_to :account
  # belongs_to :address

  enum status: { active: 0 }

  # TODO: WIP (Rough sketch to get going)
  has_many :conversations, dependent: :destroy
  has_many :customer_inboxes, dependent: :destroy
  has_many :inbox_users, dependent: :destroy
  has_many :users, through: :inbox_users, disable_joins: true
  has_many :customers, through: :customer_inboxes
  
  scope :current_inboxes, ->(current_user) { joins(:inbox_users).where(inbox_users: { user: current_user }) }
end
