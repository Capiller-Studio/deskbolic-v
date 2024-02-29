# frozen_string_literal: true

# == Schema Information
#
# Table name: canned_responses
#
#  id          :uuid             not null, primary key
#  description :text
#  identifier  :string           not null
#  name        :string
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#
# Indexes
#
#  index_canned_responses_on_account_id                 (account_id)
#  index_canned_responses_on_account_id_and_created_at  (account_id,created_at)
#  index_canned_responses_on_account_id_and_identifier  (account_id,identifier) UNIQUE
#  index_canned_responses_on_account_id_and_name        (account_id,name)
#  index_canned_responses_on_account_id_and_status      (account_id,status)
#
FactoryBot.define do
  factory :canned_response do
    name { "MyString" }
    description { "MyText" }
    account { nil }
  end
end
