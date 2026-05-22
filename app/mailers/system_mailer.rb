# frozen_string_literal: true

class SystemMailer < ApplicationMailer
  layout "mailer"

  # Send a test email with pre-compiled HTML body.
  # Used by the email template builder's "Send Test" feature.
  def test_template(to:, subject:, body:)
    mail(to: to, subject: subject) do |format|
      format.html { render html: body.html_safe }
    end
  end

  # Stub for future system emails: invoices, marketing, alerts
  # Example:
  # def invoice(account, invoice)
  #   @account = account
  #   @invoice = invoice
  #   mail(to: @account.email, subject: "Your Invoice ##{@invoice.number}")
  # end
  #
  # def welcome(user)
  #   @user = user
  #   mail(to: @user.email, subject: "Welcome to Deskbolic!")
  # end
end
