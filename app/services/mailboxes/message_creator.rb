# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Mailboxes
  class MessageCreator < ApplicationService
    attr_accessor :mail, :account, :parsed_mail, :inbox, :sender,
                  :html_content_parsed, :text_content_parsed, :conversation, :message

    def initialize(mail:, parsed_mail:, account:, inbox:, sender:, conversation:)
      self.mail                = mail
      self.parsed_mail         = parsed_mail
      self.inbox               = inbox
      self.sender              = sender
      self.account             = account
      self.conversation        = conversation
      self.html_content_parsed = parsed_mail.html_content_parsed
      self.text_content_parsed = parsed_mail.text_content_parsed
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
      self.message = conversation.messages.create!(
        account:,
        sender:,
        content: (html_content_parsed.presence || text_content_parsed).to_s.truncate(60_000),
        inbox:,
        external_id: mail.message_id,
        data: {
          email: {}
        }
      )
    end

    def find_message
      conversation.messages.find_by(external_id: mail.message_id)
    end

    def process_attachments
      attachments = parsed_mail.attachments.first(10)

      inline_attachments  = attachments.select { |attachment| attachment[:original].inline? }
      regular_attachments = attachments - inline_attachments

      process_inline_attachments(inline_attachments) if inline_attachments.present?
      process_regular_attachments(regular_attachments) if regular_attachments.present?

      message.save!
    end

    def process_regular_attachments(attachments)
      attachments.each do |attachment|
        resource = message.attachments.new(
          account:,
          attachment_type: :file
        )
        resource.file.attach(attachment[:blob])
      end
    end

    def process_inline_attachments(attachments)
      attachments.each do |attachment|
        process_inline_image(attachment)
      end
    end

    def process_inline_image(attachment)
      if html_content_parsed.present?
        process_html_inline_image(attachment)
      elsif text_content_parsed.present?
        process_text_inline_image(attachment)
      end
    end

    def process_html_inline_image(attachment)
      cid = attachment[:original].cid

      html_content_parsed.gsub!(
        "cid:#{cid}",
        Rails.application.routes.url_helpers.url_for(attachment[:blob]).to_s
      )
    end

    def process_text_inline_image(attachment)
      filename = attachment[:original].filename

      text_content_parsed.gsub!(
        "[image: #{filename}]",
        "<img src=\"#{Rails.application.routes.url_helpers.url_for(attachment[:blob])}\" alt=\"#{filename}\">"
      )
    end
  end
end
