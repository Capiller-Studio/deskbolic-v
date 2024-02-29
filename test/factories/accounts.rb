# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                       :uuid             not null, primary key
#  billing_data             :jsonb            not null
#  configurations           :jsonb            not null
#  data                     :jsonb            not null
#  email                    :string
#  features                 :bigint           default(0), not null
#  identifier               :string           not null
#  limits                   :jsonb            not null
#  locale                   :string           default("en"), not null
#  name                     :string           not null
#  referral_approved_at     :datetime
#  referral_code            :string           not null
#  referral_commission      :decimal(10, 2)
#  referral_commission_type :integer          default("fixed"), not null
#  referral_paid_at         :datetime
#  referred_by_commission   :decimal(10, 2)
#  status                   :integer          default("active"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  address_id               :uuid
#  referred_by_id           :uuid
#
# Indexes
#
#  index_accounts_on_created_at      (created_at)
#  index_accounts_on_identifier      (identifier) UNIQUE
#  index_accounts_on_name            (name)
#  index_accounts_on_referral_code   (referral_code) UNIQUE
#  index_accounts_on_referred_by_id  (referred_by_id)
#  index_accounts_on_status          (status)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id) ON DELETE => nullify
#  fk_rails_...  (referred_by_id => accounts.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :account do
    name { "MyString" }
    locale { "MyString" }
    email { "MyString" }
    features { "" }
    limits { "" }
    data { "" }
    configurations { "" }
    status { 1 }
    username { "MyString" }
  end
end
