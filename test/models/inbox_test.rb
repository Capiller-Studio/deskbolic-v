# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                     :uuid             not null, primary key
#  channel_type           :string           not null
#  configurations         :jsonb            not null
#  default_locale         :string           default("en"), not null
#  display_name           :string
#  flags                  :integer          default(0), not null
#  name                   :string           default(""), not null
#  status                 :integer          default("active"), not null
#  timezone               :string           default("UTC"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  business_hour_group_id :uuid
#  channel_id             :uuid             not null
#
# Indexes
#
#  index_inboxes_on_account_id                 (account_id)
#  index_inboxes_on_account_id_and_created_at  (account_id,created_at)
#  index_inboxes_on_account_id_and_name        (account_id,name)
#  index_inboxes_on_account_id_and_status      (account_id,status)
#  index_inboxes_on_business_hour_group_id     (business_hour_group_id)
#  index_inboxes_on_channel                    (channel_type,channel_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => nullify
#
require "test_helper"

class InboxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
