# frozen_string_literal: true

module Dashboard
  module InboxesHelper
    def inbox_channel_icon(inbox)
      if inbox.channel.present?
        channel_overview_icon(inbox.channel)
      else
        "email.svg"
      end
    end

    def inbox_channel_type_label(inbox)
      if inbox.channel.present?
        channel_overview_type_label(inbox.channel)
      else
        t("dashboard.inboxes.general", default: "General Inbox")
      end
    end

    def inbox_channel_identifier(inbox)
      if inbox.channel.present?
        channel_overview_identifier(inbox.channel)
      else
        inbox.name
      end
    end

    def inbox_channel_edit_path(inbox)
      return nil unless inbox.channel.present?

      channel_overview_edit_path(inbox.channel)
    end
  end
end
