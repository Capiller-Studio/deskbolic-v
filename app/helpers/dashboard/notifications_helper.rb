# frozen_string_literal: true

module Dashboard
  module NotificationsHelper
    NOTIFICATION_ICONS = {
      "conversation_created" => "notification_conversation_created.svg",
      "conversation_assigned" => "notification_conversation_assigned.svg",
      "conversation_resolved" => "notification_conversation_resolved.svg",
      "sla_breached" => "notification_sla_breached.svg",
      "message_created" => "notification_message_created.svg",
      "conversation_mention" => "notification_conversation_mention.svg",
      "subscription_created" => "notification_subscription_created.svg",
      "subscription_renewed" => "notification_subscription_renewed.svg",
      "subscription_cancelled" => "notification_subscription_cancelled.svg",
      "trial_expiring" => "notification_trial_expiring.svg",
      "payment_failed" => "notification_payment_failed.svg",
      "limit_approaching" => "notification_limit.svg",
      "limit_reached" => "notification_limit.svg",
      "team_assigned" => "notification_team_assigned.svg"
    }.freeze

    def notification_icon_for(event)
      NOTIFICATION_ICONS.fetch(event.to_s, "notification.svg")
    end
  end
end
