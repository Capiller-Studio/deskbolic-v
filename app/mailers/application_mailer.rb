# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }
  layout "mailer"

  private

  def default_from_address
    Rails.application.credentials.dig(:mailer, :from) || "noreply@deskbolic.com"
  end

  # Dedicated from address for channel-based emails (helpdesk replies, CSAT, etc.)
  # Separate from system deskbolic.com sender to protect domain reputation.
  def helpbolic_from_address
    "support@helpbolic.com"
  end
end
