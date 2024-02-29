# frozen_string_literal: true

# == Schema Information
#
# Table name: filters
#
#  id          :uuid             not null, primary key
#  conditions  :jsonb            not null
#  description :text
#  filter_type :integer          default("conversation"), not null
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#  user_id     :uuid             not null
#
# Indexes
#
#  index_filters_on_account_id                  (account_id)
#  index_filters_on_account_id_and_created_at   (account_id,created_at)
#  index_filters_on_account_id_and_filter_type  (account_id,filter_type)
#  index_filters_on_account_id_and_name         (account_id,name)
#  index_filters_on_user_id                     (user_id)
#
FactoryBot.define do
  factory :filter do
    name { "MyString" }
    filter_type { 1 }
    conditions { "" }
    account { nil }
    user { nil }
    description { "MyText" }
  end
end
