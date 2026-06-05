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

  def forward_email_verification(email_channel)
    @email_channel = email_channel
    @account = email_channel.account

    # The subject contains the unique token which ActionMailbox will extract
    subject = "Deskbolic Forwarding Verification: [#{@email_channel.forward_email_token}]"
    
    # Send it TO the custom email address the user wants to forward
    # It should eventually reach the system's generated forward_email address
    mail(to: email_channel.email, from: "no-reply@helpbolic.com", subject: subject)
  end

  def subscription_reminder(account)
    @account = account
    @subscription = account.active_subscription || account.subscriptions.order(created_at: :desc).first
    
    mail(to: @account.email, subject: I18n.t("mailers.system_mailer.subscription_reminder.subject", default: "Action Required: Your Deskbolic subscription trial is ending soon"))
  end

  def subscription_past_due(account)
    @account = account
    @subscription = account.subscriptions.order(created_at: :desc).first
    
    mail(to: @account.email, subject: I18n.t("mailers.system_mailer.subscription_past_due.subject", default: "Action Required: Your Deskbolic subscription is past due"))
  end
end
