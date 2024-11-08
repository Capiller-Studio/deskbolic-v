# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class MessageCreator < ApplicationService
      SUPPORTED_ATTACHMENT_TYPES = %w[
        image
        video
        audio
        file
        share
        story_mention
        location
        fallback
      ].freeze
      attr_accessor :parsed_message, :account, :inbox, :sender,
                    :conversation, :message, :facebook_page_channel

      def initialize(parsed_message:, account:, inbox:, sender:, conversation:, facebook_page_channel:)
        self.parsed_message        = parsed_message
        self.inbox                 = inbox
        self.sender                = sender
        self.account               = account
        self.conversation          = conversation
        self.facebook_page_channel = facebook_page_channel
      end

      def call
        # TODO: Important -> Use correct shard based on current-account

        ActiveRecord::Base.transaction do
          unless find_message
            create_message
            process_attachments
          end
        end
        message
      end

      private

      def create_message
        # TODO: Handle parsed_message.reply_to_mid
        # Convert external id to Array
        self.message = conversation.messages.create!(
          account:,
          sender:,
          content: parsed_message.content,
          inbox:,
          external_id: parsed_message.mid,
          data: {}
        )
      end

      def find_message
        self.message = conversation.messages.find_by(external_id: parsed_message.mid)
      end

      def process_attachments
        parsed_message.attachments.to_a.each do |attachment|
          process_attachment(attachment)
        end
      end

      # TODO: WIP
      def supported_attachment?(attachment)
        # TODO: validate attachment type -> attachment["type"]
        # [image, audio, video, file, template, fallback]
        SUPPORTED_ATTACHMENT_TYPES.include?(attachment["type"])
      end

      def process_attachment(attachment)
        attachment_type = attachment["type"].to_s

        if %w[image video audio file share story_mention].include?(attachment_type)
          process_file_attachment(attachment, attachment_type)
        elsif ["location"].include?(attachment_type)
          process_location_attachment(attachment, attachment_type)
        elsif ["fallback"].include?(attachment_type)
          process_fallback_attachment(attachment, attachment_type)
        end
      end

      def process_file_attachment(attachment, attachment_type)
        url = attachment["payload"]["url"]
        tempfile = download_file(url)
        file_attachment = message.attachments.create!(
          remote_url: url,
          account:,
          attachment_type: parse_attachment_type(attachment_type, tempfile)
        )
        attach_file(file_attachment, tempfile)
        process_story_attachment(file_attachment) if file_attachment.attachment_type == "story_mention"
      end

      def process_location_attachment(attachment)
        location_attachment = message.attachments.create!(
          remote_url: attachment["url"],
          latitude: attachment["payload"]["coordinates"]["lat"],
          longitude: attachment["payload"]["coordinates"]["long"],
          alt_title: attachment["title"],
          account:,
          attachment_type:
        )
        attach_file(location_attachment)
      end

      def process_fallback_attachment(attachment)
        location_attachment = message.attachments.create!(
          remote_url: attachment["url"],
          alt_title: attachment["title"],
          account:,
          attachment_type:
        )
        attach_file(location_attachment)
      end

      def attach_file(attachment, tempfile = nil)
        return if attachment.remote_url.blank?

        tempfile ||= Down.download(attachment.remote_url)
        attachment.file.attach(
          io: tempfile,
          filename: tempfile.original_filename,
          content_type: tempfile.content_type
        )
      end

      def download_file(url)
        return if url.blank?

        Down.download(url)
      end

      def parse_attachment_type(attachment_type, tempfile)
        return attachment_type unless ["share", "story_mention"].include?(attachment_type)
        return attachment_type unless tempfile

        Utilities::AttachmentTypeHelpers.attachment_type(tempfile.content_type)
      end

      def fetch_story(_external_id)
        client = Koala::Facebook::API.new(facebook_page_channel.access_token)
        client.get_object(source_id, fields: %w[story from])
      rescue Koala::Facebook::AuthenticationError
        # TODO: Exception handling
      rescue Koala::Facebook::ClientError => _e
        # TODO: Exception handling
      rescue StandardError => _e
        # TODO: Exception handling
      end

      def process_story_attachment(_attachment)
        story = fetch_story(parsed_message.mid)

        return if story.blank?

        story["story"]["mention"]["id"]
        story["from"]["username"]

        # TODO: Handle stories
      end
    end
  end
end
