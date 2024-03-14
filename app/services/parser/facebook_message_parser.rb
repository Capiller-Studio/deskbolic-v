# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Parser
  class FacebookMessageParser < ApplicationService
    attr_accessor :message

    def initialize(response:)
      self.message = JSON.parse(response)
      self.message = message["messaging"] || message["standby"]
    end

    def call
      # TODO: Return a hash or maybe some object
      self
    end

    def mid
      @mid ||= message.dig("message", "mid")
    end

    def sender_id
      @sender_id ||= message.dig("sender", "id")
    end

    def recipient_id
      @recipient_id ||= message.dig("recipient", "id")
    end

    def content
      @content ||= message.dig("message", "text")
    end

    def attachments
      @attachments ||= message.dig("message", "attachments")
    end

    def sequence
      @sequence ||= message.dig("message", "seq")
    end

    def reply_to_mid
      @reply_to_mid ||= message.dig("message", "reply_to", "mid")
    end

    def timestamp
      @timestamp ||= message["timestamp"]
    end

    def delivery
      @delivery ||= message["delivery"]
    end

    def read
      @read ||= message["read"]
    end

    def read_watermark
      @read_watermark ||= read&.dig("watermark")
    end

    def delivery_watermark
      @delivery_watermark ||= delivery&.dig("watermark")
    end

    def echo?
      @echo ||= message.dig("message", "is_echo")
    end
  end
end
