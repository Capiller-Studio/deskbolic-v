# frozen_string_literal: true

class VerificationMailbox < ApplicationMailbox
  def process
    subject = mail.subject.to_s

    # Extract the token from the subject string: "Deskbolic Forwarding Verification: [TOKEN]"
    match = subject.match(/Deskbolic Forwarding Verification: \[(.+?)\]/)
    return unless match

    token = match[1]

    # Find the correct shard via GlobalRouting using the recipient email addresses
    all_recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
    all_recipients.compact.map(&:downcase).uniq.each do |recipient|
      routing = GlobalRouting.find_by(route_type: "forward_email", route_value: recipient)
      next unless routing

      # Switch to the correct shard using the account
      routing.account.with_shard do
        channel = Channel::Email.find_by(forward_email: recipient, forward_email_token: token)
        if channel
          channel.update!(forwarding_verified_at: Time.current)
          return
        end
      end
    end
  end
end
