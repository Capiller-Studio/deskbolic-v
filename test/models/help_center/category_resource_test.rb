# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_category_resources
#
#  id            :uuid             not null, primary key
#  position      :integer          default(0), not null
#  resource_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_id   :uuid             not null
#  resource_id   :uuid             not null
#
# Indexes
#
#  idx_on_category_id_resource_id_resource_type_3ce5a596a2  (category_id,resource_id,resource_type) UNIQUE
#  index_help_center_category_resources_on_category_id      (category_id)
#  index_help_center_category_resources_on_position         (position)
#  index_help_center_category_resources_on_resource         (resource_type,resource_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => help_center_categories.id) ON DELETE => cascade
#
require "test_helper"

module HelpCenter
  class CategoryResourceTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
