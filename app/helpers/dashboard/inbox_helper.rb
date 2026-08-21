# frozen_string_literal: true

module Dashboard
  module InboxHelper
    CHANNEL_TAG_TYPES = {
      "Channel::FacebookPage" => "facebook",
      "Channel::Instagram" => "instagram",
      "Channel::Whatsapp" => "whatsapp",
      "Channel::Email" => "email",
      "Channel::ContactForm" => "contact-form",
      "Channel::Custom" => "custom-widget",
      "Channel::WebWidget" => "web-widget"
    }.freeze

    CHANNEL_TAG_LABELS = {
      "facebook" => "Facebook",
      "instagram" => "Instagram",
      "whatsapp" => "WhatsApp",
      "email" => "Email support",
      "contact-form" => "Contact Form",
      "custom-widget" => "Custom Widget",
      "web-widget" => "Web widget"
    }.freeze

    def inbox_icon(inbox)
      icon = case inbox.channel_type
      when "Channel::FacebookPage" then "dashboard_channel_facebook.svg"
      when "Channel::Instagram"    then "dashboard_channel_instagram.svg"
      when "Channel::Whatsapp"     then "dashboard_channel_whatsapp.svg"
      when "Channel::Email"        then "dashboard_channel_email.svg"
      when "Channel::ContactForm"  then "dashboard_channel_contact_form.svg"
      when "Channel::Custom"       then "dashboard_channel_custom.svg"
      else "dashboard_channel_web_widget.svg"
      end

      inline_svg_tag(icon, class: "link-icon", aria: { hidden: true })
    end

    def inbox_channel_tag_type(inbox)
      CHANNEL_TAG_TYPES.fetch(inbox.channel_type, "web-widget")
    end

    def inbox_channel_tag_label(inbox)
      CHANNEL_TAG_LABELS.fetch(inbox_channel_tag_type(inbox))
    end

    def dashboard_sidebar_view_items(sidebar_counts, unread_counts)
      [
        { key: nil, label: t("dashboard.sidebar.channels.all_conversations", default: "All conversations"), icon: "dashboard_all_conversations.svg", count: sidebar_counts&.dig(:all) || 0 },
        { key: "assigned", label: t("dashboard.sidebar.channels.assigned_to_me", default: "Assigned to me"), icon: "dashboard_assigned.svg", count: sidebar_counts&.dig(:assigned) || 0 },
        { key: "unassigned", label: t("dashboard.conversations.filter_unassigned", default: "Unassigned"), icon: "dashboard_unassigned.svg", count: sidebar_counts&.dig(:unassigned) || 0 },
        { key: "mentions", label: t("dashboard.sidebar.channels.mentions", default: "Mentions"), icon: "dashboard_mentions.svg", count: sidebar_counts&.dig(:mentions) || unread_counts&.dig(:mentions) || 0 },
        { key: "snoozed", label: t("enums.conversation.status.snoozed", default: "Snoozed"), icon: "dashboard_snoozed.svg", count: sidebar_counts&.dig(:snoozed) || 0 },
        { key: "resolved", label: t("enums.conversation.status.resolved", default: "Resolved"), icon: "dashboard_resolved.svg", count: sidebar_counts&.dig(:resolved) || 0 }
      ]
    end
  end
end
