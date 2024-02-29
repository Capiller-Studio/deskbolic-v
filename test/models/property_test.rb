# frozen_string_literal: true

# == Schema Information
#
# Table name: properties
#
#  id           :uuid             not null, primary key
#  conditions   :jsonb            not null
#  description  :text
#  display_name :string
#  display_type :integer          default("text"), not null
#  name         :string           not null
#  value_type   :integer          default("string"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :uuid             not null
#
# Indexes
#
#  index_properties_on_account_id                 (account_id)
#  index_properties_on_account_id_and_created_at  (account_id,created_at)
#  index_properties_on_account_id_and_name        (account_id,name)
#
require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
