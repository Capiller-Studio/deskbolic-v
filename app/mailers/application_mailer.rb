# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }
  layout "mailer"

  after_action :set_delivery_options

  private

  def default_from_address
    Rails.application.credentials.dig(:mailer, :from) || "noreply@deskbolic.com"
  end

  # Dedicated from address for channel-based emails (helpdesk replies, CSAT, etc.)
  # Separate from system deskbolic.com sender to protect domain reputation.
  def helpbolic_from_address
    "support@helpbolic.com"
  end

  # Dynamically route emails ending in @helpbolic.com through the Helpbolic SMTP relay.
  # Other emails (e.g., noreply@deskbolic.com) will fall back to the default SMTP in production.rb
  def set_delivery_options
    return unless Rails.env.production?
    
    # Only override if the mail object exists and from address ends with @helpbolic.com
    # AND the mail object doesn't already have custom delivery settings (from ConversationReplyMailer)
    return unless mail && mail.from.present?
    
    from_address = mail.from.first.to_s
    
    if from_address.end_with?("helpbolic.com")
      mail.delivery_method(:smtp, {
        address: "mail.helpbolic.com",
        port: 587,
        domain: "helpbolic.com",
        user_name: Rails.application.credentials.helpbolic_smtp_username,
        password: Rails.application.credentials.helpbolic_smtp_password,
        authentication: "plain",
        enable_starttls_auto: true
      })
    end
  end
end
