# frozen_string_literal: true

# == Schema Information
#
# Table name: mentions
#
#  id             :uuid             not null, primary key
#  mentioned_type :string           not null
#  resource_type  :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  mentioned_id   :uuid             not null
#  resource_id    :uuid             not null
#
# Indexes
#
#  index_mentions_on_account_id     (account_id)
#  index_mentions_on_mentioned      (mentioned_type,mentioned_id)
#  index_mentions_on_resource       (resource_type,resource_id)
#  index_mentions_on_unique_record  (resource_id,resource_type,mentioned_id,mentioned_type) UNIQUE
#
FactoryBot.define do
  factory :mention do
    account { nil }
    resource { nil }
    mentioned { nil }
  end
end
