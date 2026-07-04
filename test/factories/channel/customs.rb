# frozen_string_literal: true

FactoryBot.define do
  factory :channel_custom, class: "Channel::Custom" do
    identifier { "custom-#{SecureRandom.hex(4)}" }
    webhook_url { "https://api.example.com/webhook" }
    name { "My Custom Channel" }
    description { "Test custom channel" }
    configurations { {} }
    data { {} }
    headers { { "Authorization" => "Bearer xyz" } }
    response_mapping { { "identifier" => "customer.id", "name" => "customer.name" } }
    account
  end
end
