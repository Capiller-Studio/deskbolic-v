# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class MessageCreator < ApplicationService
        MESSAGE_TYPES_WITHOUT_ATTACHMENTS = %w[text
                                               button
                                               interactive
                                               location
                                               contacts].freeze

        ATTACHMENT_TYPE_MAPPING = {
          "image" => :image,
          "sticker" => :image,
          "contacts" => :contact,
          "location" => :location,
          "audio" => :audio,
          "voice" => :audio,
          "video" => :video,
          "file" => :file
        }.freeze

        API_ENDPOINT = Rails.application.credentials.dig(Rails.env.to_sym, :channels, :whatsapp, :api_endpoint)
        API_HEADERS = {
          "Content-Type" => "application/json"
        }.freeze

        attr_accessor :parsed_message, :account, :inbox, :sender,
                      :conversation, :message, :whatsapp_channel,
                      :message_type

        def initialize(parsed_message:, account:, inbox:, sender:, conversation:, whatsapp_channel:, message_type:)
          self.parsed_message        = parsed_message
          self.inbox                 = inbox
          self.sender                = sender
          self.account               = account
          self.conversation          = conversation
          self.whatsapp_channel      = whatsapp_channel
          self.message_type          = message_type
        end

        def call
          # TODO: Important -> Use correct shard based on current-account

          ActiveRecord::Base.transaction do
            create_messages unless find_message
          end
          message
        end

        private

        def find_message
          # TODO: WIP
          # self.message = conversation.messages.find_by(external_id: parsed_message)
        end

        def parse_attachment_type(source_attachment_type)
          ATTACHMENT_TYPE_MAPPING[source_attachment_type] || :file
        end

        def create_messages
          # TODO: Process all messages

          message_params = parsed_message[:messages].first

          # TODO: Error handling and logging
          return if message_params.key?("errors")

          message_type == "contacts" ? process_contact_messages(message_params) : process_message(message_params)
        end

        def process_contact_messages(message_params)
          message_params["contacts"].each do |contact_params|
            create_message(contact_params)
            attach_contact(contact_params)
            message.save!
          end
        end

        def process_message(message_params)
          create_message(message_params)
          attach_files
          attach_location if message_type == "location"
          message.save!
        end

        def attach_files
          return if MESSAGE_TYPES_WITHOUT_ATTACHMENTS.include?(message_type)

          attachment_payload = parsed_message[:messages].first[message_type.to_sym]
          message.content ||= attachment_payload[:caption]

          attachment_file = download_attachment_file(attachment_payload)
          return if attachment_file.blank?

          message.attachments.new(
            account: account,
            attachment_type: parse_attachment_type(message_type),
            file: {
              io: attachment_file,
              filename: attachment_file.original_filename,
              content_type: attachment_file.content_type
            }
          )
        end

        def attach_location
          location = parsed_message[:messages].first["location"]
          location_name = location["name"] ? "#{location['name']}, #{location['address']}" : ""
          message.attachments.new(
            account: account,
            attachment_type: parse_attachment_type(message_type),
            latitude: location["latitude"],
            longitude: location["longitude"],
            alt_title: location_name,
            remote_url: location["url"]
          )
        end

        def attach_contact(contact_params)
          # TODO: Error handling if phones.blank?

          contact_params[:phones].each do |phone|
            message.attachments.new(
              account: account,
              attachment_type: parse_attachment_type(message_type),
              alt_title: phone[:phone].to_s
            )
          end
        end

        def create_message(message_params)
          # TODO: Convert external id to Array
          self.message = conversation.messages.build(
            content: message_content(message_params),
            account: account,
            inbox: inbox,
            sender: sender,
            external_id: message_params[:id].to_s,
            external_reply_to_id: message_params["context"]&.[]("id")
          )
        end

        def download_attachment_file(attachment_payload)
          response = HTTParty.get(
            "#{API_ENDPOINT}/v13.0/#{attachment_payload[:id]}",
            headers: inbox.channel.api_headers
          )

          whatsapp_channel.authorization_error! && return if response.unauthorized?

          return unless response.success?

          Down.download(
            response.parsed_response["url"],
            headers: api_headers
          )
        end

        def message_content(message_params)
          # TODO: Handle buttons & interactive messages

          message_params.dig(:text, :body) ||
            message_params.dig(:button, :text) ||
            message_params.dig(:interactive, :button_reply, :title) ||
            message_params.dig(:interactive, :list_reply, :title) ||
            message_params.dig(:name, :formatted_name)
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
