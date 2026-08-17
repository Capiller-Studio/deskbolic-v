# frozen_string_literal: true

class ReplyMailbox < ApplicationMailbox
  before_processing :find_conversation
  before_processing :find_email_channel

  attr_accessor :email_channel, :conversation, :account

  def process
    Mailboxes::ConversationCreator.call(mail: mail, email_channel: email_channel, conversation: conversation)
  end

  private

  def find_conversation
    parsed_mail = Parser::MailParser.new(mail: mail)
    extracted_identifier = parsed_mail.reply_to_conversation_uuid

    # Strategy 1: System Domain Parsing (Fast Path)
    # If the reply was sent to `reply+<identifier>@<account>.helpbolic.com`, we can
    # directly extract the account from the domain and find the conversation.
    if extracted_identifier.present?
      recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
      reply_address = recipients.compact.find { |addr| addr.match?(/reply\+[^@]+@/i) }
      domain = reply_address&.split("@")&.last

      if domain&.end_with?(".helpbolic.com")
        account_identifier = domain.split(".").first
        self.account = Account.find_by(identifier: account_identifier.upcase)

        if self.account
          self.account.with_shard do
            self.conversation = self.account.conversations.find_by(identifier: extracted_identifier.upcase)
          end
        end
      end
    end

    # Strategy 2: Header Parsing (Fallback Path)
    # If the domain wasn't `.helpbolic.com` (e.g. they replied to `ahsan@gmail.com` and it was auto-forwarded),
    # or the identifier couldn't be found, we fall back to standard header parsing.
    if conversation.blank?
      self.email_channel = Channels::EmailChannelSearcher.call(mail: mail)&.first
      self.account ||= email_channel&.account

      if email_channel && account
        account.with_shard do
          # Try the identifier again just in case it was a valid UUID/ID but not a .helpbolic.com domain
          if extracted_identifier.present?
            self.conversation = account.conversations.find_by(identifier: extracted_identifier.upcase)
          end

          # Check In-Reply-To header
          if conversation.blank? && parsed_mail.in_reply_to.present?
            message = account.messages.find_by(external_id: parsed_mail.in_reply_to)
            self.conversation = message&.conversation
          end

          # Check References header
          if conversation.blank? && parsed_mail.references.present?
            parsed_mail.references.find_each do |ref|
              message = account.messages.find_by(external_id: ref)
              if message
                self.conversation = message.conversation
                break
              end
            end
          end
        end
      end
    end

    Rails.logger.info("ReplyMailbox: No existing conversation found, will create new") if conversation.blank?
  end

  def find_email_channel
    # If we already found the conversation via global subdomain, we don't strictly need an email_channel.
    return if conversation.present?

    # Otherwise, it must match an email_channel (for custom forward_email addresses)
    self.email_channel ||= Channels::EmailChannelSearcher.call(mail: mail)&.first
    bounced! unless email_channel
  end

  def current_account
    @current_account ||= account || email_channel&.account
  end
end
