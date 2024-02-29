# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_short_messages
#
#  id                 :uuid             not null, primary key
#  configurations     :jsonb            not null
#  data               :jsonb            not null
#  full_phone_number  :string
#  name               :string
#  phone_code         :string
#  phone_number       :string
#  service            :integer          default("twilio"), not null
#  service_identifier :string
#  short_message_type :integer          default("sms"), not null
#  status             :integer          default("active"), not null
#  tokens             :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :uuid             not null
#
# Indexes
#
#  index_channel_short_messages_on_account_id                      (account_id)
#  index_channel_short_messages_on_account_id_and_created_at       (account_id,created_at)
#  index_channel_short_messages_on_account_id_and_name             (account_id,name)
#  index_channel_short_messages_on_full_phone_number               (full_phone_number) UNIQUE
#  index_channel_short_messages_on_service_and_service_identifier  (service,service_identifier) UNIQUE
#  index_channel_short_messages_on_status                          (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class ShortMessage < ApplicationRecord
    belongs_to :account

    enum status:  { active: 0 }
    enum service: { twilio: 0 }
    enum short_message_type:  { sms: 0 }
  end
end
