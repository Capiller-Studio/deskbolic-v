# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }
  layout "mailer"

  after_action :set_delivery_options

  private

  def default_from_address
    Rails.application.credentials.dig(:mailer, :from) || "no-reply@deskbolic.com"
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
      username = ENV["HELPBOLIC_SMTP_USERNAME"].presence || Rails.application.credentials.helpbolic_smtp_username
      password = ENV["HELPBOLIC_SMTP_PASSWORD"].presence || Rails.application.credentials.helpbolic_smtp_password
      
      if username.present? && password.present?
        mail.delivery_method(:smtp, {
          address: ENV.fetch("HELPBOLIC_SMTP_ADDRESS", "mail.helpbolic.com"),
          port: ENV.fetch("HELPBOLIC_SMTP_PORT", 587).to_i,
          domain: ENV.fetch("HELPBOLIC_SMTP_DOMAIN", "helpbolic.com"),
          user_name: username,
          password: password,
          authentication: "plain",
          enable_starttls_auto: true
        })
      end
    end
  end
end
