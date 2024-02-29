# frozen_string_literal: true

FactoryBot.define do
  factory :label do
    title { "MyString" }
    description { "MyText" }
    color { "MyString" }
    configurations { "" }
    flags { 1 }
    account { nil }
  end
end
