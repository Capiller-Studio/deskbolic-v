# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id              :uuid             not null, primary key
#  configurations  :jsonb            not null
#  content         :text
#  content_type    :integer          default("text"), not null
#  data            :jsonb            not null
#  locale          :string
#  sender_type     :string           not null
#  sentiment       :jsonb            not null
#  status          :integer          default("sent"), not null
#  visibility      :integer          default("global"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  conversation_id :uuid             not null
#  external_id     :string
#  inbox_id        :uuid             not null
#  sender_id       :uuid             not null
#
# Indexes
#
#  index_messages_on_account_id                        (account_id)
#  index_messages_on_account_id_and_external_id        (account_id,external_id)
#  index_messages_on_conversation_id                   (conversation_id)
#  index_messages_on_conversation_id_and_content_type  (conversation_id,content_type)
#  index_messages_on_conversation_id_and_created_at    (conversation_id,created_at)
#  index_messages_on_conversation_id_and_status        (conversation_id,status)
#  index_messages_on_inbox_id                          (inbox_id)
#  index_messages_on_sender                            (sender_type,sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
class Message < ShardRecord
  belongs_to :conversation
  belongs_to :inbox
  belongs_to :account
  belongs_to :sender, polymorphic: true

  enum status: { sent: 0 }
  enum content_type: { text: 0 }
  enum visibility: { personal: 0, global: 1 }
end
