# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_emails
#
#  id                  :uuid             not null, primary key
#  configurations      :jsonb            not null
#  email               :string
#  forward_email       :string
#  imap_configurations :jsonb            not null
#  name                :string
#  service             :integer
#  smtp_configurations :jsonb            not null
#  status              :integer          default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#
# Indexes
#
#  index_channel_emails_on_account_id                 (account_id)
#  index_channel_emails_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_emails_on_account_id_and_name        (account_id,name)
#  index_channel_emails_on_email                      (email) UNIQUE
#  index_channel_emails_on_forward_email              (forward_email) UNIQUE
#  index_channel_emails_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :channel_email, class: "Channel::Email" do
    email { "MyString" }
    forward_email { "MyString" }
    imap_configurations { "" }
    smtp_configurations { "" }
    account { nil }
    configurations { "" }
  end
end
