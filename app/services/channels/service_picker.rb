# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  class ServicePicker < ApplicationService
    attr_accessor :channel, :inbox, :customer_inbox, :message, :conversation

    def initialize(conversation:, message:)
      self.conversation      = conversation
      self.channel           = conversation.inbox.channel
      self.inbox             = conversation.inbox
      self.customer_inbox    = find_customer_inbox 
      self.message           = message
    end

    def call
      deliver_message if channel.present?
    end

    private

    def deliver_message
      send("#{inbox.channel_type.underscore.parameterize(separator: "_")}_service")
    end

    def channel_email_service
    end

    def channel_short_message_external_id_service
    end

    def channel_whatsapp_service
      Channels::Whatsapp::CloudApi::MessageSender.call(whatsapp_channel: channel, customer: customer_inbox.customer, message: message)
    end

    def channel_api_service
    end

    def channel_web_widget_service
    end
    
    def channel_facebook_page_service
      Channels::FacebookPages::MessageSender.call(facebook_page_channel: channel, customer_inbox: customer_inbox, message: message)
    end
    
    def find_customer_inbox
      CustomerInbox.where(customer_id: conversation.conversation_members.where(member_type: "Customer").last.member_id).first
    end
  end
end