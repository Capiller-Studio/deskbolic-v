# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_web_widgets
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  flags             :integer          default(0), not null
#  name              :string
#  secret            :string           not null
#  status            :integer          default("active"), not null
#  ui_configurations :jsonb            not null
#  website_url       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#
# Indexes
#
#  index_channel_web_widgets_on_account_id                 (account_id)
#  index_channel_web_widgets_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_web_widgets_on_account_id_and_name        (account_id,name)
#  index_channel_web_widgets_on_status                     (status)
#  index_channel_web_widgets_on_website_url                (website_url)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :channel_web_widget, class: "Channel::WebWidget" do
    website_url { "MyString" }
    domain { "MyString" }
    configurations { "" }
    data { "" }
    secret { "MyString" }
    account { nil }
  end
end
