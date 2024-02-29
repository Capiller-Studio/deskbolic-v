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
#  status            :integer          default("active"), not null
#  status_changed_at :datetime
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  campaign_id       :uuid
#  inbox_id          :uuid             not null
#
# Indexes
#
#  index_conversations_on_account_id                       (account_id)
#  index_conversations_on_account_id_and_created_at        (account_id,created_at)
#  index_conversations_on_account_id_and_identifier        (account_id,identifier)
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
FactoryBot.define do
  factory :conversation do
    account { nil }
    inbox { nil }
    status { 1 }
    title { "MyString" }
    configurations { "" }
    data { "" }
    identifier { "MyString" }
    priority { 1 }
    status { 1 }
    status_changed_at { "2024-02-21 02:08:14" }
    last_activity_at { "2024-02-21 02:08:14" }
    first_respond_at { "2024-02-21 02:08:14" }
    campaign { nil }
  end
end
