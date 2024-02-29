# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_subscriptions
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  name              :string
#  subscription_type :integer          default("push"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_user_id_subscription_type_c17965cf4e                 (user_id,subscription_type)
#  index_notification_subscriptions_on_user_id                 (user_id)
#  index_notification_subscriptions_on_user_id_and_created_at  (user_id,created_at)
#
FactoryBot.define do
  factory :notification_subscription do
    subscription_type { 1 }
    user { nil }
    name { "MyString" }
    configurations { "" }
  end
end
