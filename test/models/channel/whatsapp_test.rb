# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_whatsapps
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  full_phone_number :string           not null
#  name              :string
#  phone_code        :string
#  phone_number      :string
#  service           :integer
#  status            :integer          default("active"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#
# Indexes
#
#  index_channel_whatsapps_on_account_id                 (account_id)
#  index_channel_whatsapps_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_whatsapps_on_account_id_and_name        (account_id,name)
#  index_channel_whatsapps_on_full_phone_number          (full_phone_number) UNIQUE
#  index_channel_whatsapps_on_service                    (service)
#  index_channel_whatsapps_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
require "test_helper"

module Channel
  class WhatsappTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
