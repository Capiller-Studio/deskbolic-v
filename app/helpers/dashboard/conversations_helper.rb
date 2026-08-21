# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module ConversationsHelper
    def assigned_conversation
      @conversation.assigned?
    end

    def assigned_team
      @conversation.team
    end

    def single_emoji_message?(content)
      text = content.to_s.strip
      return false if text.blank?

      clusters = text.scan(/\X/)
      return false unless clusters.one?

      single_emoji_pattern = /
        \A
        (?:
          (?:[\u{1F1E6}-\u{1F1FF}]{2}) |
          (?:[0-9#*]\uFE0F?\u20E3) |
          (?:
            (?:\p{Emoji_Presentation}|\p{Extended_Pictographic}\uFE0F?)
            \p{Emoji_Modifier}?
            (?:
              \u200D
              (?:\p{Emoji_Presentation}|\p{Extended_Pictographic}\uFE0F?)
              \p{Emoji_Modifier}?
            )*
          )
        )
        \z
      /x

      text.match?(single_emoji_pattern)
    end

    def conversation_list_scope(inbox:, team_id:, teams:, assignee_id:, account:, filter:)
      return inbox.name if inbox
      return teams.find { |team| team.id.to_s == team_id.to_s }&.name if team_id.present?
      return account.users.find_by(id: assignee_id)&.display_name if assignee_id.present?

      conversation_filter_label(filter) if filter.present?
    end

    def conversation_filter_label(filter)
      {
        "assigned" => t("dashboard.conversations.filter_assigned", default: "Assigned to me"),
        "unassigned" => t("dashboard.conversations.filter_unassigned", default: "Unassigned"),
        "mentions" => t("dashboard.sidebar.channels.mentions", default: "Mentions"),
        "snoozed" => t("enums.conversation.status.snoozed", default: "Snoozed"),
        "resolved" => t("enums.conversation.status.resolved", default: "Resolved")
      }[filter.to_s]
    end

    def conversation_filter_items(list_counts)
      [
        { key: nil, label: t("dashboard.conversations.filter_all"), count: list_counts&.dig(:all) || 0 },
        { key: "assigned", label: t("dashboard.conversations.filter_assigned"), count: list_counts&.dig(:assigned) || 0 },
        { key: "unassigned", label: t("dashboard.conversations.filter_unassigned"), count: list_counts&.dig(:unassigned) || 0 },
        { key: "resolved", label: t("enums.conversation.status.resolved", default: "Resolved"), count: list_counts&.dig(:resolved) || 0 }
      ]
    end

    def conversation_list_time(last_activity)
      return unless last_activity
      return last_activity.strftime("%H:%M") if last_activity.to_date == Date.current
      return t("datetime.distance_in_words.x_days", count: 1, default: "Yesterday") if last_activity.to_date == Date.yesterday

      last_activity.strftime("%d %b")
    end

    def message_delivery_status(message)
      return t("dashboard.messages.status.failed") if message.failed?
      return t("dashboard.messages.status.read") if message.read?
      return t("dashboard.messages.status.delivered") if message.delivered?

      t("dashboard.messages.status.sent")
    end
  end
end
