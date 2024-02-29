# frozen_string_literal: true

# == Schema Information
#
# Table name: chat_bot_inboxes
#
#  id          :uuid             not null, primary key
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  chat_bot_id :uuid             not null
#  inbox_id    :uuid             not null
#
# Indexes
#
#  index_chat_bot_inboxes_on_chat_bot_id                          (chat_bot_id)
#  index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id             (chat_bot_id,inbox_id) UNIQUE
#  index_chat_bot_inboxes_on_chat_bot_id_and_inbox_id_and_status  (chat_bot_id,inbox_id,status)
#  index_chat_bot_inboxes_on_created_at                           (created_at)
#  index_chat_bot_inboxes_on_inbox_id                             (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (chat_bot_id => chat_bots.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :chat_bot_inbox do
    chat_bot { nil }
    inbox { nil }
    status { 1 }
  end
end
