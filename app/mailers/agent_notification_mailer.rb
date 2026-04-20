# frozen_string_literal: true

class AgentNotificationMailer < ApplicationMailer
  layout "mailer"

  # General notification — uses DB template (Liquid) if available, else mailer view
  def notify(notification)
    @notification = notification
    @user = notification.user
    @account = notification.account
    @resource = notification.resource

    locale = @user.locale || I18n.default_locale
    template = EmailTemplate.for_account(@account, EmailTemplate::AGENT_NOTIFICATION)

    if template
      I18n.with_locale(locale) do
        rendered_subject = template.render_subject(notification_liquid_variables)
        rendered_body = template.render_body(notification_liquid_variables)

        mail(to: @user.email, subject: rendered_subject) do |format|
          format.html { render html: rendered_body.html_safe }
        end
      end
    else
      I18n.with_locale(locale) do
        subject = I18n.t("mailers.agent_notification.#{notification.event}.subject",
                         identifier: @resource.try(:identifier) || "")
        mail(to: @user.email, subject:)
      end
    end
  end

  # Conversation assigned — always from mailer view
  def conversation_assigned(notification)
    @notification = notification
    @user = notification.user
    @conversation = notification.resource

    locale = @user.locale || I18n.default_locale
    I18n.with_locale(locale) do
      subject = I18n.t("mailers.agent_notification.conversation_assigned.subject",
                       identifier: @conversation.identifier)
      mail(to: @user.email, subject:)
    end
  end

  # SLA breach — always from mailer view
  def sla_breached(notification)
    @notification = notification
    @user = notification.user
    @conversation = notification.resource

    locale = @user.locale || I18n.default_locale
    I18n.with_locale(locale) do
      subject = I18n.t("mailers.agent_notification.sla_breached.subject",
                       identifier: @conversation.identifier)
      mail(to: @user.email, subject:)
    end
  end

  private

  def notification_liquid_variables
    {
      "agent_name" => @user.display_name || @user.email,
      "event_title" => I18n.t("notifications.events.#{@notification.event}"),
      "event_description" => I18n.t("notifications.events.#{@notification.event}"),
      "identifier" => @resource.try(:identifier) || "",
      "inbox_name" => @resource.try(:inbox).try(:name) || ""
    }
  end
end
