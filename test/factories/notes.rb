# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    title { "MyString" }
    content { "MyText" }
    resource { nil }
    user { nil }
    account { nil }
  end
end
