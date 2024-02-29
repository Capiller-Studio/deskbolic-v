# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_articles
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  flags          :integer          default(0), not null
#  position       :integer
#  slug           :string           not null
#  status         :integer          default("active"), not null
#  views_count    :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  portal_id      :uuid             not null
#
# Indexes
#
#  index_help_center_articles_on_account_id                (account_id)
#  index_help_center_articles_on_portal_id                 (portal_id)
#  index_help_center_articles_on_portal_id_and_created_at  (portal_id,created_at)
#  index_help_center_articles_on_portal_id_and_flags       (portal_id,flags)
#  index_help_center_articles_on_portal_id_and_position    (portal_id,position)
#  index_help_center_articles_on_portal_id_and_slug        (portal_id,slug) UNIQUE
#  index_help_center_articles_on_portal_id_and_status      (portal_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
require "test_helper"

module HelpCenter
  class ArticleTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
