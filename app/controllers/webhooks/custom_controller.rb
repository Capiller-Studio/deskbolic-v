# frozen_string_literal: true

module Webhooks
  class CustomController < Webhooks::BaseController
    before_action :set_channel
    before_action :authenticate_webhook!

    def create
      webhook = store_incoming_webhook(source: "custom", payload: params.to_unsafe_h)
      ::Webhooks::CustomEventListenWorker.perform_async(webhook.id)
      head :ok
    end

    private

    def set_channel
      @channel = Channel::Custom.find_by(id: params[:channel_id], account_id: params[:account_id])
      head :not_found unless @channel
    end

    def authenticate_webhook!
      provided_token = request.headers["X-Deskbolic-Token"]
      
      # Use secure compare to prevent timing attacks
      unless provided_token.present? && ActiveSupport::SecurityUtils.secure_compare(@channel.hmac_token, provided_token)
        head :unauthorized
      end
    end
  end
end
