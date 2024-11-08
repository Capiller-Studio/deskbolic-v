# frozen_string_literal: true

class AdminNotificationMailer < ApplicationMailer
  default from: Rails.application.credentials.emails_from_address
  layout "admin_notification_mailer"

  def workspace_request(account, user)
    @account = account
    @user    = user

    mail(
      to: @account.email,
      subject: "Workspace Joining Request"
    )
  end
end
