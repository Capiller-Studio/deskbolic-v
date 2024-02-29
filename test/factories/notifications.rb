# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id            :uuid             not null, primary key
#  event         :integer          default("conversation_created"), not null
#  read_at       :datetime
#  resource_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null
#  resource_id   :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_notifications_on_account_id              (account_id)
#  index_notifications_on_resource                (resource_type,resource_id)
#  index_notifications_on_user_id                 (user_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at)
#  index_notifications_on_user_id_and_event       (user_id,event)
#
FactoryBot.define do
  factory :notification do
    account { nil }
    notification_type { 1 }
    user { nil }
    resource { nil }
    read_at { "2024-02-21 18:18:19" }
  end
end
