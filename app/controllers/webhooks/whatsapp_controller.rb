# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Webhooks
  class WhatsappController < ApplicationController
    skip_forgery_protection only: [:index, :hub]

    def index
      # Support both per-channel routing and global routing
      native_params = JSON.parse(params.to_unsafe_h.to_json)
      
      # Inject channel_id if passed in URL (manual setup)
      native_params["channel_id"] = params[:channel_id] if params[:channel_id].present?

      Webhooks::WhatsappEventListenWorker.perform_async(native_params)

      head(:ok)
    end

    def hub
      if valid_secret?(params["hub.verify_token"])
        render plain: params["hub.challenge"]
      else
        render status: :unauthorized, json: { error: "Invalid Token" }
      end
    end

    private

    def valid_secret?(secret)
      return false if secret.blank?

      if params[:channel_id].present? && params[:account_id].present?
        # Manual setup: per-channel verification
        account = Account.find_by(id: params[:account_id])
        return false unless account

        account.with_shard do
          channel = Channel::Whatsapp.find_by(id: params[:channel_id])
          return channel && channel.webhook_secret == secret
        end
      else
        # Embedded setup: global Meta App verify token
        global_verify_token = Rails.application.credentials.dig(:channels, :whatsapp, :verify_token)
        secret == global_verify_token
      end
    end
  end
end
