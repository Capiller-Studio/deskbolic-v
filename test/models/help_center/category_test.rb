# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_categories
#
#  id             :uuid             not null, primary key
#  ancestry       :string
#  ancestry_depth :integer          default(0), not null
#  children_count :integer          default(0), not null
#  code           :string           not null
#  configurations :jsonb            not null
#  flags          :integer          default(0), not null
#  hidden         :boolean          default(FALSE), not null
#  identifier     :string           not null
#  permalink      :string           not null
#  position       :integer
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  portal_id      :uuid             not null
#
# Indexes
#
#  index_help_center_categories_on_account_id                (account_id)
#  index_help_center_categories_on_portal_id                 (portal_id)
#  index_help_center_categories_on_portal_id_and_ancestry    (portal_id,ancestry)
#  index_help_center_categories_on_portal_id_and_created_at  (portal_id,created_at)
#  index_help_center_categories_on_portal_id_and_flags       (portal_id,flags)
#  index_help_center_categories_on_portal_id_and_hidden      (portal_id,hidden)
#  index_help_center_categories_on_portal_id_and_identifier  (portal_id,identifier) UNIQUE
#  index_help_center_categories_on_portal_id_and_permalink   (portal_id,permalink) UNIQUE
#  index_help_center_categories_on_portal_id_and_position    (portal_id,position)
#  index_help_center_categories_on_portal_id_and_status      (portal_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
require "test_helper"

module HelpCenter
  class CategoryTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
