# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                   :uuid             not null, primary key
#  access_token         :string           not null
#  configurations       :jsonb            not null
#  data                 :jsonb            not null
#  instagram_identifier :string
#  name                 :string
#  page_identifier      :string           not null
#  status               :integer          default("active"), not null
#  tokens               :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :uuid             not null
#
# Indexes
#
#  index_channel_facebook_pages_on_account_id                      (account_id)
#  index_channel_facebook_pages_on_account_id_and_created_at       (account_id,created_at)
#  index_channel_facebook_pages_on_account_id_and_name             (account_id,name)
#  index_channel_facebook_pages_on_account_id_and_page_identifier  (account_id,page_identifier) UNIQUE
#  index_channel_facebook_pages_on_instagram_identifier            (instagram_identifier)
#  index_channel_facebook_pages_on_page_identifier                 (page_identifier)
#  index_channel_facebook_pages_on_status                          (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
require "test_helper"

module Channel
  class FacebookPageTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
