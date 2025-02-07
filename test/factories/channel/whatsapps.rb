# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: channel_whatsapps
#
#  id                  :uuid             not null, primary key
#  api_key             :string
#  configurations      :jsonb            not null
#  data                :jsonb            not null
#  full_phone_number   :string           not null
#  name                :string
#  phone_code          :string
#  phone_number        :string
#  service             :integer          default("cloud_api"), not null
#  status              :integer          default("active"), not null
#  webhook_secret      :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#  business_account_id :string
#  phone_number_id     :string
#
# Indexes
#
#  index_channel_whatsapps_on_account_id                 (account_id)
#  index_channel_whatsapps_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_whatsapps_on_account_id_and_name        (account_id,name)
#  index_channel_whatsapps_on_full_phone_number          (full_phone_number) UNIQUE
#  index_channel_whatsapps_on_service                    (service)
#  index_channel_whatsapps_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
# rubocop:enable Metrics/LineLength
FactoryBot.define do
  factory :channel_whatsapp, class: "Channel::Whatsapp" do
    phone_code { "MyString" }
    phone_number { "MyString" }
    configurations { "" }
    data { "" }
    account { nil }
  end
end
