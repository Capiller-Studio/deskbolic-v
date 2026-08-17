# frozen_string_literal: true

module Dashboard
  module Channels
    module CustomHelper
      def custom_channel_response_mapping_options(account = current_account)
        # Standard Options
        options = {
          "Customer Attributes" => [
            [ "Identifier (External ID)", "customer.identifier" ],
            [ "Name", "customer.name" ],
            [ "First Name", "customer.first_name" ],
            [ "Last Name", "customer.last_name" ],
            [ "Email", "customer.email" ],
            [ "Phone Number", "customer.phone_number" ],
            [ "Avatar URL", "customer.avatar_url" ]
          ],
          "Message Attributes" => [
            [ "Message Content", "message.content" ],
            [ "Message External ID", "message.external_id" ]
          ],
          "Conversation Attributes" => [
            [ "Conversation External ID", "conversation.external_id" ]
          ]
        }

        # Custom Fields for Customer
        customer_custom_fields = account.custom_fields.entity_type_customer
        if customer_custom_fields.any?
          options["Customer Custom Attributes"] = customer_custom_fields.map do |cf|
            [ cf.key.titleize, "customer.custom_attributes.#{cf.key}" ]
          end
        end

        # Custom Fields for Conversation
        conversation_custom_fields = account.custom_fields.entity_type_conversation
        if conversation_custom_fields.any?
          options["Conversation Custom Attributes"] = conversation_custom_fields.map do |cf|
            [ cf.key.titleize, "conversation.custom_attributes.#{cf.key}" ]
          end
        end

        options
      end
    end
  end
end
