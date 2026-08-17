# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # Route replies first, then new conversations as fallback.
  # Spam/auto-reply emails are bounced before reaching any mailbox.
  routing(
    ->(inbound_email) { verification_email?(inbound_email) } => :verification,
    ->(inbound_email) { forwarding_confirmation?(inbound_email) } => :conversation,
    ->(inbound_email) { spam_or_auto_reply?(inbound_email) } => :bounce,
    ->(inbound_email) { reply_email?(inbound_email) } => :reply,
    ->(inbound_email) { new_conversation?(inbound_email) } => :conversation,
    all: :bounce
  )

  def self.verification_email?(inbound_email)
    mail = inbound_email.mail

    # Must be originally sent by our system's channel domain
    return false unless Array(mail.from).any? { |address| address.end_with?("@helpbolic.com") }

    # Must match the verification token subject format
    return false unless mail.subject.to_s.match?(/Deskbolic Forwarding Verification: \[.+?\]/)

    # Additionally, verify that at least one recipient is registered in GlobalRouting
    all_recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
    all_recipients.compact.map(&:downcase).uniq.any? do |recipient|
      GlobalRouting.exists?(route_type: "forward_email", route_value: recipient)
    end
  end

  def self.forwarding_confirmation?(inbound_email)
    mail = inbound_email.mail

    # Gmail Forwarding Confirmation
    return true if Array(mail.from).any? { |addr| addr.match?(/forwarding-noreply@google\.com/i) }

    # Generic Forwarding Confirmations (Outlook/Microsoft/Yahoo)
    return true if mail.subject.to_s.match?(/forwarding confirmation/i)

    false
  end

  # Detect auto-generated emails, bounces, out-of-office replies etc.
  def self.spam_or_auto_reply?(inbound_email)
    mail = inbound_email.mail

    # Auto-Submitted header (RFC 3834)
    auto_submitted = mail["Auto-Submitted"]&.value.to_s.downcase
    return true if auto_submitted.present? && auto_submitted != "no"

    # Common auto-reply headers
    return true if mail["X-Autoreply"]&.value.present?
    return true if mail["X-Auto-Response-Suppress"]&.value.present?

    # Bulk/junk precedence
    return true if %w[bulk junk list].include?(mail["Precedence"]&.value.to_s.downcase)

    # Mailer-daemon / postmaster bounces
    return true if Array(mail.from).any? { |addr| addr.match?(/mailer-daemon|postmaster/i) }

    false
  end

  # Check if the email is a reply to an existing conversation:
  # 1. reply+<uuid>@domain address pattern
  # 2. In-Reply-To header matching an existing message
  # 3. References header matching an existing message
  def self.reply_email?(inbound_email)
    mail = inbound_email.mail

    # Strategy 1: reply+<uuid>@domain address pattern
    all_recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
    return true if all_recipients.compact.any? { |addr| addr.match?(/reply\+[^@]+@/i) }

    # Strategy 2: In-Reply-To header
    return true if mail.in_reply_to.present?

    # Strategy 3: References header
    return true if mail.references.present?

    false
  end

  # A new conversation is valid if we can find an email channel for it
  def self.new_conversation?(inbound_email)
    find_email_channel(inbound_email).present?
  end

  def self.find_email_channel(inbound_email)
    Channels::EmailChannelSearcher.call(mail: inbound_email.mail)&.first
  end
end
