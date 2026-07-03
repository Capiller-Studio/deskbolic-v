# frozen_string_literal: true

module Webhooks
  class ApiController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :set_channel
    before_action :authenticate_webhook!

    def create
      ::Webhooks::ApiEventListenWorker.perform_async(@channel.account_id, @channel.id, params.to_unsafe_h)
      head :ok
    end

    private

    def set_channel
      @channel = Channel::Api.find_by(id: params[:channel_id], account_id: params[:account_id])
      head :not_found unless @channel
    end

    def authenticate_webhook!
      provided_secret = request.headers["X-Api-Secret"]
      
      # Use secure compare to prevent timing attacks
      unless provided_secret.present? && ActiveSupport::SecurityUtils.secure_compare(@channel.webhook_secret, provided_secret)
        head :unauthorized
      end
    end
  end
end
