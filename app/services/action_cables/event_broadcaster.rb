# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module ActionCables
  class EventBroadcaster < ApplicationService
    attr_accessor :data, :connection_tokens, :resource, :event, :body, :headers, :timestamp, :signature

    def initialize(data:, event:, connection_tokens: )
      self.data               = data
      self.event              = event
      self.connection_tokens  = connection_tokens
      self.timestamp          = Time.now.to_i
    end

    def call
      configure_body
      # configure_headers
      # send_webhook
      broadcast
      
    rescue StandardError
      false
    end
    
    private
    
    def broadcast
      connection_tokens.each do |connection_token|
        ActionCable.server.broadcast(
          connection_token,
          body
        )
      end
    end

    def configure_body
      self.body = {
        event: event,
        object: data
      }
    end

    def configure_headers
      # self.headers = {
      #   "Signature" => "t=#{timestamp},v1=#{generate_signature}",
      #   "Content-Type" => "application/json"
      # }
    end

    def generate_signature
      # OpenSSL::HMAC.hexdigest("SHA256", account.webhook_secret, "#{timestamp}-#{body}")
    end

    def send_webhook
      # response = HTTParty.post(
      #   account.webhook_endpoint,
      #   body: body,
      #   headers: headers,
      #   basic_auth: { username: account.webhook_username, password: account.webhook_password }
      # )

      # response.success?
    end
  end
end