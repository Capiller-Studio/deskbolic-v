# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Mailboxes
  class ConversationCreator < ApplicationService
    attr_accessor :mail, :email_channel, :account, :parsed_mail, :inbox, :sender,
                  :conversation

    def initialize(mail:, email_channel:)
      self.mail          = mail
      self.email_channel = email_channel
      self.account       = email_channel.account
    end

    def call
      # TODO: Important -> Use correct shard based on current-account
      self.parsed_mail = ::Parser::MailParser.call(mail:)
      find_inbox

      ActiveRecord::Base.transaction do
        find_or_create_sender
        find_or_create_conversation
        create_message
      end
    end

    private

    def find_inbox
      # TODO: Logic for finding the correct inbox. Maybe: One inbox will act as default and other inboxes will
      # receive onversations/messages based on Filters
      self.inbox = email_channel.inboxes.first
    end

    def find_or_create_conversation
      find_conversation || create_conversation
      find_or_create_conversation_memeber
    end

    def find_conversation
      # TODO: Maybe we need to allow replies here as well
      # Possibilities: reply-to header or some pattern in receiver header
      # mail.in_reply_to || mail["In-Reply-To"].try(:value)
      # account.conversations.find_by(external_id: mail.in_reply_to)
      # Plus we will have something like reply+conversation-id@domain.com for replies.
      nil
    end

    def create_conversation
      # TODO: Fix placeholder identifier
      self.conversation = account.conversations.create!(
        inbox:,
        source: :email,
        identifier: SecureRandom.uuid,
        data: {
          email: { subject: parsed_mail.subject }
        }
      )
    end

    def find_or_create_sender
      find_user || find_customer || create_customer
    end

    def find_user
      self.sender = inbox.users.find_by(email: parsed_mail.original_sender.downcase)
    end

    def find_or_create_customer
      find_customer || create_customer
    end

    def find_customer
      self.sender = inbox.customers.find_by(email: parsed_mail.original_sender.downcase)
    end

    def create_customer
      self.sender = Customers::CustomerCreator.call(
        account:,
        inbox:,
        external_id: parsed_mail.original_sender,
        email: parsed_mail.original_sender,
        params: {
          name: find_customer_name,
          data: {
            email: { message_id: mail.message_id }
          }
        }
      )
    end

    def find_customer_name
      parsed_mail.sender_name.presence || parsed_mail.from.first.split("@").first
    end

    def find_or_create_conversation_memeber
      conversation.conversation_members.find_or_create_by!(conversation:, member: sender, account:)
    end

    def create_message
      MessageCreator.call(
        account:,
        inbox:,
        conversation:,
        mail:,
        parsed_mail:,
        sender:
      )
    end
  end
end
