# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Webhooks
  class WhatsappController < ApplicationController
    skip_before_action :verify_authenticity_token, only: :index

    def index
      Rails.logger.info("Webhooks::Whatsapp=> headers: #{headers} params: #{params}")

      params = JSON.parse(params.to_unsafe_h.to_json)
      Webhooks::WhatsappEventListenWorker.perform_async(params)

      head(:ok)
    end

    def hub
      if valid_secret?(params["hub.verify_token"])
        render(json: params["hub.challenge"])
      else
        render(status: :unauthorized, json: { error: "Invalid Token" })
      end
    end

    private

    def valid_secret?(secret)
      whatsapp_channel = Channel::Whatsapp.find(params[:channel_id])

      secret == whatsapp_channel.webhook_secret if whatsapp_channel.webhook_secret
    end
  end
end
