# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }
  layout "mailer"

  private

  def default_from_address
    Rails.application.credentials.dig(:mailer, :from) || "noreply@deskbolic.com"
  end
end
