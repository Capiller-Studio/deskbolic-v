# frozen_string_literal: true

class SystemMailer < ApplicationMailer
  layout "mailer"

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
