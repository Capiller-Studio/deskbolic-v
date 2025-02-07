# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Webhooks
  class WhatsappEventListenWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: "default"

    def perform(params = {})
      params = params.with_indifferent_access

      channel = find_channel(params)
      return unless channel_active?(channel)

      return unless channel.cloud_api?

      Channels::Whatsapp::CloudApi::EventListner.call(whatsapp_channel: channel,
                                                      params: params).perform
    end

    private

    def find_channel(params)
      return find_wb_channel(params) if params["object"] == "whatsapp_business_account"

      Channel::Whatsapp.find_by(id: params["channel_id"])
    end

    def find_wb_channel(params)
      phone_number = "+#{params['entry'].first['changes'].first.dig('value', 'metadata', 'display_phone_number')}"
      phone_number_id = params["entry"].first["changes"].first.dig("value", "metadata", "phone_number_id")

      channel = Channel::Whatsapp.find_by(full_phone_number: phone_number)

      return channel if channel && channel.phone_number_id == phone_number_id
    end

    def channel_active?(channel)
      if channel.blank? || channel.reauthorization_required? || !channel.active? || !channel.account.active?
        return false
      end

      true
    end
  end
end
