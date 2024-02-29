# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: related_resources
#
#  id                   :uuid             not null, primary key
#  linked_resource_type :string           not null
#  resource_type        :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  linked_resource_id   :uuid             not null
#  resource_id          :uuid             not null
#
# Indexes
#
#  index_related_resources_on_linked_resource  (linked_resource_type,linked_resource_id)
#  index_related_resources_on_resource         (resource_type,resource_id)
#  index_related_resources_on_unique_record    (resource_id,resource_type,linked_resource_id,linked_resource_type) UNIQUE
#
# rubocop:enable Metrics/LineLength
require "test_helper"

class RelatedResourceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
