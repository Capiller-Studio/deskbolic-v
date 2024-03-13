# frozen_string_literal: true

# == Schema Information
#
# Table name: conversations
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  first_respond_at  :datetime
#  identifier        :string           not null
#  last_activity_at  :datetime
#  locale            :string
#  priority          :integer          default("low"), not null
#  source            :integer
#  status            :integer          default("active"), not null
#  status_changed_at :datetime
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  campaign_id       :uuid
#  external_id       :string
#  inbox_id          :uuid             not null
#
# Indexes
#
#  index_conversations_on_account_id                       (account_id)
#  index_conversations_on_account_id_and_created_at        (account_id,created_at)
#  index_conversations_on_account_id_and_external_id       (account_id,external_id)
#  index_conversations_on_account_id_and_identifier        (account_id,identifier) UNIQUE
#  index_conversations_on_account_id_and_last_activity_at  (account_id,last_activity_at)
#  index_conversations_on_account_id_and_priority          (account_id,priority)
#  index_conversations_on_account_id_and_status            (account_id,status)
#  index_conversations_on_account_id_and_title             (account_id,title)
#  index_conversations_on_campaign_id                      (campaign_id)
#  index_conversations_on_inbox_id                         (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id) ON DELETE => nullify
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
class Conversation < ShardRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :campaign, optional: true

  enum status: { active: 0 }
  enum priority: { low: 0, medium: 1, high: 2 }
  enum source: { email: 0 }, _suffix: true

  # TODO: WIP (Rough sketch to get going)
  has_many :conversation_members, dependent: :destroy
  has_many :members, through: :conversation_members
  has_many :messages, dependent: :destroy

  after_create_commit :broadcast_conversation_creation

  private

  # TODO: Refactor to seperate concern
  def broadcast_conversation_creation
    # TODO: Broadcast event and create notification
    # Create a worker for broadcasting events in the background
  end
end
