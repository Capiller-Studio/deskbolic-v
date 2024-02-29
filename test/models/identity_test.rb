# frozen_string_literal: true

# == Schema Information
#
# Table name: identities
#
#  id                 :uuid             not null, primary key
#  administration_url :string
#  configurations     :jsonb            not null
#  first_name         :string
#  headers            :jsonb            not null
#  identifier         :string           not null
#  last_name          :string
#  middle_name        :string
#  name               :string
#  params             :jsonb            not null
#  response_mapping   :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :uuid             not null
#  address_id         :uuid
#  customer_id        :uuid             not null
#  external_id        :string
#  identity_source_id :uuid             not null
#
# Indexes
#
#  index_identities_on_account_id                          (account_id)
#  index_identities_on_account_id_and_created_at           (account_id,created_at)
#  index_identities_on_account_id_and_external_id          (account_id,external_id)
#  index_identities_on_account_id_and_identifier           (account_id,identifier) UNIQUE
#  index_identities_on_account_id_and_name                 (account_id,name)
#  index_identities_on_customer_id                         (customer_id)
#  index_identities_on_customer_id_and_identity_source_id  (customer_id,identity_source_id) UNIQUE
#  index_identities_on_identity_source_id                  (identity_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id) ON DELETE => cascade
#  fk_rails_...  (identity_source_id => identity_sources.id) ON DELETE => cascade
#
require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
