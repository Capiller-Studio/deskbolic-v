# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class MessageSender < ApplicationService
        API_ENDPOINT = Rails.application.credentials.dig(Rails.env.to_sym, :channels, :whatsapp, :api_endpoint)
        API_HEADERS = {
          "Content-Type" => "application/json"
        }.freeze

        attr_accessor :whatsapp_channel, :customer, :message

        def initialize(whatsapp_channel:, customer:, message:)
          self.whatsapp_channel    = whatsapp_channel
          self.customer            = customer
          self.message             = message
        end

        def call
          # TODO: Important -> Use correct shard based on current-account

          if message.attachments.present?
            send_attachment_message
          elsif message.content_type == "interactive"
            # TODO: Add additional content types eg. buttons, textboxes, select input etc. Then replace this placeholder
            send_interactive_text_message
          else
            send_text_message
          end
        rescue StandardError => e
          log_exception(e)
          # TODO: Exception handling
        end

        private

        def send_text_message
          response = HTTParty.post(
            "#{phone_number_endpoint}/messages",
            headers: api_headers,
            body: {
              messaging_product: "whatsapp",
              context: message_context,
              to: customer.full_phone_number,
              text: { body: message.content },
              type: "text"
            }.to_json
          )

          process_response(response)
        end

        def send_attachment_message
          # TODO: Limit to single attachment for whatsapp messages.

          attachment = message.attachments.first
          attachment_type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : "document"
          attachment_content = {
            link: attachment.direct_download_url
          }
          attachment_content["caption"] = message.content unless %w[audio sticker].include?(type)
          attachment_content["filename"] = attachment.file.filename if type == "document"

          response = HTTParty.post(
            "#{phone_number_endpoint}/messages",
            headers: api_headers,
            body: {
              :messaging_product => "whatsapp",
              :context => message_context,
              "to" => customer.full_phone_number,
              "type" => attachment_type,
              attachment_type.to_s => attachment_content
            }.to_json
          )

          process_response(response)
        end

        def send_interactive_text_message
          # TODO: WIP

          # response = HTTParty.post(
          #   "#{phone_number_endpoint}/messages",
          #   headers: api_headers,
          #   body: {
          #     messaging_product: 'whatsapp',
          #     to: customer.full_phone_number,
          #     interactive: payload,
          #     type: 'interactive'
          #   }.to_json
          # )

          # process_response(response)
        end

        def process_response(response)
          if response.success?
            # message.external_id = response["messages"].first["id"]
            message.update!(external_id: response["messages"].first["id"])
          else
            # TODO: Error handling
          end
        end

        def log_error(_response)
          # TODO: Error handling
          message.update!(status: :failed)
        end

        def log_exception(_error)
          # TODO: Error handling
          message.update!(status: :failed)

          # TODO: Ask user to re-enter credentials
        end

        def message_context
          return if message.external_reply_to_id.blank?

          {
            message_id: message.external_reply_to_id
          }
        end

        def phone_number_endpoint
          "#{API_ENDPOINT}/v13.0/#{whatsapp_channel.phone_number_id}"
        end

        def business_account_endpoint
          "#{API_ENDPOINT}/v14.0/#{whatsapp_channel.business_account_id}"
        end

        def api_headers
          API_HEADERS.merge({
                              "Authorization" => "Bearer #{whatsapp_channel.api_key}"
                            })
        end
      end
    end
  end
end
