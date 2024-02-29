# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id :uuid             not null, primary key
#
class ChannelTwilioSm < ApplicationRecord
  belongs_to :account
end
