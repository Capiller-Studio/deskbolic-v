# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id                :uuid             not null, primary key
#  destroy_after_use :boolean          default(FALSE), not null
#  flags             :integer          default(0), not null
#  owner_type        :string           not null
#  token             :string           not null
#  valid_till        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  owner_id          :uuid             not null
#
# Indexes
#
#  index_access_tokens_on_created_at  (created_at)
#  index_access_tokens_on_owner       (owner_type,owner_id)
#  index_access_tokens_on_token       (token) UNIQUE
#
require "test_helper"

class AccessTokenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
