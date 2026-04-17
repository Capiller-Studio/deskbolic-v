# frozen_string_literal: true

class ReplyMailbox < ApplicationMailbox
  before_processing :find_email_channel
  before_processing :find_conversation

  attr_accessor :email_channel, :conversation

  def process
    Mailboxes::ConversationCreator.call(mail:, email_channel:)
  end

  private

  def find_email_channel
    self.email_channel = Channels::EmailChannelSearcher.call(mail:)&.first

    bounced! unless email_channel
  end

  def find_conversation
    parsed_mail = Parser::MailParser.new(mail:)

    # Strategy 1: reply+<uuid>@domain address pattern
    if parsed_mail.reply_to_conversation_uuid.present?
      self.conversation = email_channel.account.conversations.find_by(
        identifier: parsed_mail.reply_to_conversation_uuid
      )
    end

    # Strategy 2: In-Reply-To header matching message external_id
    if conversation.blank? && parsed_mail.in_reply_to.present?
      message = email_channel.account.messages.find_by(external_id: parsed_mail.in_reply_to)
      self.conversation = message&.conversation
    end

    # Strategy 3: References header (walk through oldest to newest)
    if conversation.blank? && parsed_mail.references.present?
      parsed_mail.references.each do |ref|
        message = email_channel.account.messages.find_by(external_id: ref)
        if message
          self.conversation = message.conversation
          break
        end
      end
    end

    # If we can't find the conversation, treat as new (ConversationCreator will create one)
    Rails.logger.info("ReplyMailbox: No existing conversation found, will create new") if conversation.blank?
  end

  def current_account
    @current_account ||= email_channel.account
  end
end
