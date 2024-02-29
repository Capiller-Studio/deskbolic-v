# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id :uuid             not null, primary key
#
FactoryBot.define do
  factory :channel_twilio_sm do
    phone_code { "MyString" }
    phone_number { "MyString" }
    token { "MyString" }
    api_key { "MyString" }
    medium { 1 }
    account { nil }
  end
end
