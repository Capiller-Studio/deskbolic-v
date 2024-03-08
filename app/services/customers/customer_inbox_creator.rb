# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Customers
  class CustomerInboxCreator < ApplicationService
    attr_accessor :customer, :account, :customer_inbox, :inbox,
                  :external_id

    def initialize(account:, customer:, inbox:, external_id: nil)
      self.account           = account
      self.inbox             = inbox
      self.external_id       = external_id
      self.customer          = customer
    end

    def call
      self.external_id ||= find_external_id
      create_customer_inbox if external_id.present?
    end

    private

    def find_external_id
      inbox.channel_type.underscore.parameterize(separator: "_")
    end

    def channel_email_external_id
      customer.email
    end

    def channel_short_message_external_id
      customer.full_phone_number
    end

    def channel_whatsapp_external_id
      customer.full_phone_number.to_s.delete("+")
    end

    def channel_api_external_id
      customer.email.presence ||
        customer.full_phone_number.presence ||
        customer.username.presence ||
        SecureRandom.uuid
    end

    def channel_web_widget_external_id
      channel_api_external_id
    end

    def create_customer_inbox
      customer.customer_inboxes.find_or_create_by!(
        inbox:,
        external_id:
      )
    end
  end
end
