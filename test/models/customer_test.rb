# frozen_string_literal: true

# == Schema Information
#
# Table name: customers
#
#  id                     :uuid             not null, primary key
#  configurations         :jsonb            not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  customer_type          :integer          default("guest"), not null
#  data                   :jsonb            not null
#  display_name           :string
#  dob                    :date
#  email                  :string           not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string
#  full_phone_number      :string
#  gender                 :integer
#  identifier             :string
#  last_activity_at       :datetime
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locale                 :string           default("en"), not null
#  locked_at              :datetime
#  middle_name            :string
#  name                   :string           default("")
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  schedular_data         :jsonb            not null
#  sign_in_count          :integer          default(0), not null
#  status                 :integer          default("active"), not null
#  tokens                 :jsonb            not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  username               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  address_id             :uuid
#  external_id            :string
#
# Indexes
#
#  index_customers_on_account_id                        (account_id)
#  index_customers_on_account_id_and_created_at         (account_id,created_at)
#  index_customers_on_account_id_and_email              (account_id,email) UNIQUE
#  index_customers_on_account_id_and_external_id        (account_id,external_id)
#  index_customers_on_account_id_and_full_phone_number  (account_id,full_phone_number)
#  index_customers_on_account_id_and_locale             (account_id,locale)
#  index_customers_on_account_id_and_name               (account_id,name)
#  index_customers_on_account_id_and_status             (account_id,status)
#  index_customers_on_account_id_and_username           (account_id,username) UNIQUE
#  index_customers_on_confirmation_token                (confirmation_token) UNIQUE
#  index_customers_on_reset_password_token              (reset_password_token) UNIQUE
#  index_customers_on_unlock_token                      (unlock_token) UNIQUE
#
require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
