# frozen_string_literal: true

# == Schema Information
#
# Table name: property_resources
#
#  id            :uuid             not null, primary key
#  position      :integer
#  resource_type :string           not null
#  value         :string           is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  property_id   :uuid             not null
#  resource_id   :uuid             not null
#
# Indexes
#
#  index_property_resources_on_property_id                  (property_id)
#  index_property_resources_on_property_id_and_resource_id  (property_id,resource_id) UNIQUE
#  index_property_resources_on_property_id_and_value        (property_id,value)
#  index_property_resources_on_resource                     (resource_type,resource_id)
#  index_property_resources_on_resource_id_and_created_at   (resource_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id) ON DELETE => cascade
#
require "test_helper"

class PropertyResourceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
