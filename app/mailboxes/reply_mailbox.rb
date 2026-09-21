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
        account_identifier = domain.split(".").first.to_s.downcase
        self.account = Account.find_by(identifier: account_identifier)

        if self.account
          self.account.with_shard do
            self.conversation = self.account.conversations.find_by(identifier: extracted_identifier.upcase)
          end
        end
      end
    end

    # Strategy 2: Channel & Header Parsing (Fallback Path)
    # If the domain wasn't `.helpbolic.com` (e.g. they replied to a custom channel address and it was auto-forwarded),
    # or the identifier couldn't be found via subdomain, we resolve the account through the channel or GlobalRouting.
    if conversation.blank?
      self.email_channel = Channels::EmailChannelSearcher.call(mail: mail)&.first
      self.account ||= email_channel&.account

      # If still not found, check GlobalRouting for forward_email entries
      if account.blank?
        all_recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
        all_recipients.compact.map(&:downcase).uniq.each do |recipient|
          routing = GlobalRouting.find_by(route_type: "forward_email", route_value: recipient)
          if routing
            self.account = routing.account
            break
          end
        end
      end

      if account
        account.with_shard do
          # Try the identifier within this account's shard
          if extracted_identifier.present?
            self.conversation = account.conversations.find_by(identifier: extracted_identifier.upcase)
          end

          # Check In-Reply-To header (checks external_id first, then message UUID if helpbolic.com)
          if conversation.blank? && parsed_mail.in_reply_to.present?
            in_reply_ids = Array(parsed_mail.in_reply_to)
            in_reply_ids.each do |ir_id|
              clean_id = ir_id.to_s.tr("<>", "").strip
              msg_uuid = clean_id.split("@").first if clean_id.end_with?("@helpbolic.com")
              message = account.messages.find_by(external_id: ir_id) ||
                        account.messages.find_by(external_id: "<#{clean_id}>")
              message ||= account.messages.find_by(id: msg_uuid) if msg_uuid.present?
              if message
                self.conversation = message.conversation
                break
              end
            end
          end

          # Check References header
          if conversation.blank? && parsed_mail.references.present?
            parsed_mail.references.each do |ref|
              ref_id = ref.to_s.tr("<>", "").strip
              ref_uuid = ref_id.split("@").first if ref_id.end_with?("@helpbolic.com")
              message = account.messages.find_by(external_id: ref)
              message ||= account.messages.find_by(id: ref_uuid) if ref_uuid.present?
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
