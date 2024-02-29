# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  configurations         :jsonb            not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  data                   :jsonb            not null
#  display_name           :string
#  dob                    :date
#  email                  :string           not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string
#  gender                 :integer          default("male"), not null
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locale                 :string           default("en"), not null
#  locked_at              :datetime
#  middle_name            :string
#  name                   :string           default("")
#  provider               :string
#  provider_uid           :string
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
#  address_id             :uuid
#
# Indexes
#
#  index_users_on_confirmation_token         (confirmation_token) UNIQUE
#  index_users_on_created_at                 (created_at)
#  index_users_on_email                      (email) UNIQUE
#  index_users_on_locale                     (locale)
#  index_users_on_name                       (name)
#  index_users_on_provider_and_provider_uid  (provider,provider_uid) UNIQUE
#  index_users_on_reset_password_token       (reset_password_token) UNIQUE
#  index_users_on_status                     (status)
#  index_users_on_unlock_token               (unlock_token) UNIQUE
#  index_users_on_username                   (username) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id) ON DELETE => nullify
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
