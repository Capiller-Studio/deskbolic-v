# frozen_string_literal: true

class ConversationMailbox < ApplicationMailbox
  before_processing :find_email_channel

  attr_accessor :email_channel

  def process
    Mailboxes::ConversationCreator.call(mail:, email_channel:)
  end

  private

  def find_email_channel
    self.email_channel = Channels::EmailChannelSearcher.call(mail:)&.first

    unless email_channel
      SystemLog.log_event("inbound_email.bounced", level: :warn, message: "No matching email channel found for #{mail.to}")
      bounced!
    end
  end

  def current_account
    @current_account ||= email_channel.account
  end
end
