# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  class EmailChannelSearcher < ApplicationService
    attr_accessor :emails, :mail

    def initialize(emails: [], mail: nil)
      self.emails     = emails
      self.mail       = mail
    end

    def call
      parse_emails_from_mail
      find_email_channels
    end

    private

    def parse_emails_from_mail
      return if mail.blank?

      self.emails += mail.to.to_a + mail.bcc.to_a + mail.cc.to_a + [mail["X-Original-To"]&.value]
    end

    def find_email_channels
      return if emails.blank?

      Channel::Email.where("email IN (:emails) OR forward_email IN (:emails)", emails:)
    end
  end
end
