# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Parser
  class MailParser < ApplicationService
    include Utilities::StringHelpers

    attr_accessor :mail

    def initialize(mail:)
      self.mail = mail
    end

    def call
      # TODO: Return a hash or maybe some object
      self
    end

    def subject
      @subject ||= change_encoding(mail.subject)
    end

    def attachments
      @attachments ||= mail.attachments.map do |attachment|
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(attachment.body.to_s),
          filename: attachment.filename,
          content_type: attachment.content_type
        )
        { original: attachment, blob: }
      end
    end

    def from
      @from ||= (mail.from.to_a + mail.reply_to.to_a).map(&:downcase)
    end

    def sender_name
      @sender_name ||= Mail::Address.new((mail[:reply_to] || @mail[:from]).value).name
    end

    def original_sender
      @original_sender ||=
        address(mail[:reply_to].try(:value)) || mail["X-Original-Sender"].try(:value) || address(from.first)
    end

    def address(email)
      Mail::Address.new(email).address
    end

    def forwarded_for
      @forwarded_for ||= mail["X-Forwarded-For"].try(:value)
    end

    def receiver
      @receiver ||= mail.to.to_a + Array(forwarded_for)
    end

    def text_content
      return unless text?

      @text_content ||= begin
        # TODO: IMPORTANT we need to do some processing here, likely trim the message based on length
        original_content = part_content(mail.text_part) || ""
        parsed_content = original_content

        # return if parsed_content.blank?

        parsed_content
      end
    end

    def text_content_parsed
      # TODO: IMPORTANT we need to do some processing here, likely trim the message based on length
      @text_content_parsed ||= text_content
    end

    def html_content
      return unless html?

      @html_content ||= begin
        # TODO: IMPORTANT we need to parse HTML and only allow some basic tags
        original_content = part_content(mail.html_part) || ""
        parsed_content = original_content

        parsed_content
      end
    end

    def html_content_parsed
      # TODO: IMPORTANT we need to parse HTML and only allow some basic tags
      @html_content_parsed ||= html_content
    end

    private

    def html?
      @html ||=
        mail.content_type.to_s.include?("text/html") || mail.html_part&.content_type&.include?("text/html")
    end

    def text?
      @text ||=
        mail.content_type.to_s.include?("text/plain") || mail.text_part&.content_type&.include?("text/plain")
    end

    def multipart?
      @multipart ||=
        mail.content_type.to_s.include?("multipart") || mail.parts.any?
    end

    def part_content(part)
      return unless html? || text?

      decoded = part&.decoded || !multipart? ? mail.decoded : ""
      change_encoding(decoded)
    end
  end
end
