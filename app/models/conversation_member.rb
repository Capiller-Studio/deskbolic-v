# frozen_string_literal: true

# == Schema Information
#
# Table name: conversation_members
#
#  id               :uuid             not null, primary key
#  last_activity_at :datetime
#  last_seen_at     :datetime
#  member_type      :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#  conversation_id  :uuid             not null
#  member_id        :uuid             not null
#
# Indexes
#
#  index_conversation_members_on_account_id                     (account_id)
#  index_conversation_members_on_conversation_id                (conversation_id)
#  index_conversation_members_on_conversation_id_and_member_id  (conversation_id,member_id) UNIQUE
#  index_conversation_members_on_member                         (member_type,member_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#
class ConversationMember < ShardRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :member, polymorphic: true
end
