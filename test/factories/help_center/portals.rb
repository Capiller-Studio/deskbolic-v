# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_portals
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  default_locale    :string           default("en"), not null
#  flags             :integer          default(0), not null
#  locales           :string           default(["\"en\""]), not null, is an Array
#  name              :string
#  status            :integer          default("active"), not null
#  ui_configurations :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  domain_id         :uuid             not null
#
# Indexes
#
#  index_help_center_portals_on_account_id                     (account_id)
#  index_help_center_portals_on_account_id_and_created_at      (account_id,created_at)
#  index_help_center_portals_on_account_id_and_default_locale  (account_id,default_locale)
#  index_help_center_portals_on_account_id_and_name            (account_id,name)
#  index_help_center_portals_on_account_id_and_status          (account_id,status)
#  index_help_center_portals_on_domain_id                      (domain_id) UNIQUE
#
FactoryBot.define do
  factory :help_center_portal, class: "HelpCenter::Portal" do
    name { "MyString" }
    configurations { {} }
    locales { ["en"] }
    default_locale { "en" }
    status { :active }
    account
    flags { 1 }
    domain
  end
end
