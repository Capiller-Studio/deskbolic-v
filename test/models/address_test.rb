# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
#  id                       :uuid             not null, primary key
#  address1                 :string
#  address2                 :string
#  alternative_phone_code   :string
#  alternative_phone_number :string
#  city                     :string(60)
#  description              :text
#  designation              :string
#  name                     :string
#  organization_name        :string
#  phone_code               :string
#  phone_number             :string
#  state_name               :string
#  title                    :string
#  zipcode                  :string(15)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  country_id               :uuid
#  national_id              :string
#  state_id                 :uuid
#
# Indexes
#
#  index_addresses_on_country_id         (country_id)
#  index_addresses_on_created_at         (created_at)
#  index_addresses_on_name               (name)
#  index_addresses_on_organization_name  (organization_name)
#  index_addresses_on_state_id           (state_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id) ON DELETE => nullify
#  fk_rails_...  (state_id => states.id) ON DELETE => nullify
#
require "test_helper"

class AddressTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
