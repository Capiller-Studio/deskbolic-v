# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class ConversationCreator < ApplicationService
        #TODO: Add support for reactions, after adding reactions model
        INVALID_MESSAGE_TYPES = %w[reaction request_welcome ephemeral unsupported]

        attr_accessor :inbox, :message, :parsed_params,
                      :whatsapp_channel, :customer, :sender_id, :account,
                      :conversation

        def initialize(whatsapp_channel:, parsed_params:, account: nil)
          self.parsed_params        = parsed_params
          self.whatsapp_channel     = whatsapp_channel
          self.account              = account || whatsapp_channel.account
        end

        def call
          find_inbox

          return if invalid_message_type?(message_type)
          return if find_existing_message(parsed_params[:messages].first[:id]) || message_creation_locked?

          lock_message_creation

          ActiveRecord::Base.transaction do
            find_or_create_customer
            find_or_create_conversation
            create_message
          end

          unlock_message_creation
        rescue StandardError => _e
          # TODO: Error handling
        end

        private

        def find_inbox
          # TODO: Logic for finding the correct inbox. Maybe: One inbox will act as default and other inboxes will
          # receive conversations/messages based on Filters
          self.inbox = whatsapp_channel.inboxes.first
        end

        def find_existing_message(external_id)
          return unless external_id
      
          account.messages.find_by(external_id: external_id)
        end


        def invalid_message_type?(message_type)
          INVALID_MESSAGE_TYPES.include?(message_type)
        end

        def message_creation_locked?
          RedisUtilities::Helpers.get(message_creation_lock_key)
        end
      
        def lock_message_creation
          return if parsed_params.try(:[], :messages).blank?
      
          RedisUtilities::Helpers.set(message_creation_lock_key, true, expiry: true)
        end
      
        def unlock_message_creation
          RedisUtilities::Helpers.delete(message_creation_lock_key)
        end

        def message_creation_lock_key
          @message_creation_lock_key ||=
          format(
            RedisUtilities::Keys::MESSAGE_CREATION_LOCK,
            account_id: account.id
            id: parsed_params[:messages].first[:id]
          )
        end

        def message_type
          @message_type ||= parsed_params[:messages].first[:type]
        end

        def find_or_create_customer
          create_customer
        end

        def create_customer
          customer_data = parsed_params[:contacts]&.first || {}

          self.customer = Customers::CustomerCreator.call(
            account:,
            inbox:,
            external_id: customer_data["wa_id"],
            full_phone_number: "+#{parsed_params[:messages].first[:from]}",
            params: {
              name: customer_data.dig(:profile, :name)
              # avatar_url: customer_data["avatar_url"]
            }
          )
        end

        def find_or_create_conversation
          find_conversation || create_conversation
          find_or_create_conversation_memeber
        end

        def find_conversation
          # TODO: We shouldn't add messages to resolved conversations. So we would need to add flags per channel or inboxes to handle all cases
          self.conversation = customer.conversations.where(inbox:).find_by(account:)
        end

        def create_conversation
          # TODO: Fix placeholder identifier
          self.conversation = account.conversations.create!(
            inbox:,
            source: :whatsapp,
            identifier: SecureRandom.uuid,
            data: {}
          )
        end

        def find_or_create_conversation_memeber
          conversation.conversation_members.find_or_create_by!(conversation:, member: customer, account:)
        end


        def create_message
          MessageCreator.call(
            account:,
            inbox:,
            conversation:,
            parsed_message: parsed_params,
            sender: customer,
            whatsapp_channel:
          )
        end
      end
    end
  end
end
