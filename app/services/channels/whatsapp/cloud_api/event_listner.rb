# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class EventListner < ApplicationService
        attr_accessor :inbox, :message, :parsed_message, :event,
                      :facebook_page_channel, :customer, :sender_id, :account,
                      :conversation

        def initialize(whatsapp_channel:, params:, account: nil)
          self.whatsapp_channel = whatsapp_channel
          self.params = params
          self.parsed_params = params[:entry].try(:first).try(:[], "changes").try(:first).try(:[], "value")
          self.account = account || whatsapp_channel.account
        end

        def call
          if parsed_params.try(:[], :statuses).present?
            process_statuses
          elsif parsed_params.try(:[], :messages).present?
            ConversationCreator.call(
              whatsapp_channel:,
              parsed_params:,
              account:
            )
          end
        rescue StandardError => _e
          # TODO: Error handling
        end

        private

        def process_statuses
          existing_message = find_message(parsed_params[:statuses].first[:id])
          return unless existing_message

          update_message_status(existing_message, parsed_params[:statuses].first)
        rescue ArgumentError => e
          Rails.logger.error("Channels::Whatsapp::CloudApi::EventListner status process error => #{e.message}")
        end

        def update_message_status(message, status)
          message.status = status[:status]
          if status[:status] == "failed" && status[:errors].present?
            # TODO: Log external errors.

            # error = status[:errors]&.first
            # message.errors = {
            #   code: error[:code],
            #   message: error[:title]
            #  }
          end
          message.save!
        end

        def find_message(external_id)
          return unless external_id

          account.messages.find_by(external_id:)
        end
      end
    end
  end
end
