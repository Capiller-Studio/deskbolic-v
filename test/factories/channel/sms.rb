# frozen_string_literal: true

FactoryBot.define do
  factory :channel_sm, class: "Channel::Sm" do
    phone_code { "MyString" }
    phone_number { "MyString" }
    provider { "MyString" }
    configurations { "" }
    data { "" }
    account { nil }
  end
end
