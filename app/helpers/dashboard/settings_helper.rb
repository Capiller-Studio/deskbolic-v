# frozen_string_literal: true

module Dashboard
  module SettingsHelper
    CHANNEL_TYPE_KEYS = {
      "Channel::Email" => "email",
      "Channel::WebWidget" => "web_widget",
      "Channel::ContactForm" => "contact_form",
      "Channel::FacebookPage" => "facebook",
      "Channel::Instagram" => "instagram",
      "Channel::Whatsapp" => "whatsapp",
      "Channel::Custom" => "custom"
    }.freeze

    CHANNEL_TYPE_LABELS = {
      "email" => "Email",
      "web_widget" => "Web Widget",
      "contact_form" => "Contact Form",
      "facebook" => "Facebook",
      "instagram" => "Instagram",
      "whatsapp" => "WhatsApp",
      "custom" => "Custom"
    }.freeze

    CHANNEL_TYPE_ICONS = {
      "email" => "email.svg",
      "web_widget" => "widget.svg",
      "contact_form" => "contact_form.svg",
      "facebook" => "facebook.svg",
      "instagram" => "instagram.svg",
      "whatsapp" => "whatsapp.svg",
      "custom" => "custom_ch.svg"
    }.freeze

    def channel_overview_type(channel)
      CHANNEL_TYPE_KEYS.fetch(channel.class.name)
    end

    def channel_overview_type_label(channel_or_type)
      type = channel_or_type.is_a?(String) ? channel_or_type : channel_overview_type(channel_or_type)
      CHANNEL_TYPE_LABELS.fetch(type)
    end

    def channel_overview_icon(channel_or_type)
      type = channel_or_type.is_a?(String) ? channel_or_type : channel_overview_type(channel_or_type)
      CHANNEL_TYPE_ICONS.fetch(type)
    end

    def channel_overview_name(channel)
      channel.name.presence || channel_overview_identifier(channel).presence || channel_overview_type_label(channel)
    end

    def channel_overview_identifier(channel)
      case channel
      when Channel::Email
        channel.email.presence || channel.forward_email
      when Channel::WebWidget
        Array(channel.allowed_hosts).first
      when Channel::ContactForm
        t("dashboard.channels_overview.embedded_form", default: "Embedded form")
      when Channel::FacebookPage
        channel.page_identifier
      when Channel::Instagram
        channel.username.present? ? "@#{channel.username.delete_prefix('@')}" : channel.instagram_id
      when Channel::Whatsapp
        channel.full_phone_number
      when Channel::Custom
        channel.identifier
      end
    end

    def channel_overview_embed_code(channel, account)
      channel_path =
        case channel
        when Channel::WebWidget then "w"
        when Channel::ContactForm then "f"
        end
      return if channel_path.nil?

      widget_app_url = (ENV["WIDGET_APP_URL"].presence || "https://widget.deskbolic.com").delete_suffix("/")
      %(<script src="#{widget_app_url}/#{channel_path}/#{account.id}/#{channel.id}/embed.js"></script>)
    end

    def channel_overview_logo(channel)
      return channel.avatar_url if channel.respond_to?(:avatar_url) && channel.avatar_url.present?
      return channel.scaled_logo if channel.is_a?(Channel::WebWidget) && channel.logo.attached?

      nil
    end

    def channel_overview_status(channel)
      return "disconnected" if channel.respond_to?(:reauthorization_required?) && channel.reauthorization_required?
      return "active" if channel.respond_to?(:active?) && channel.active?

      "disconnected"
    end

    def channel_overview_token_message(channel)
      return unless channel.is_a?(Channel::Instagram) && channel.expires_at.present?

      if channel.token_expired?
        t(
          "dashboard.channels_overview.token_expired",
          time: time_ago_in_words(channel.expires_at),
          default: "Token expired %{time} ago"
        )
      else
        t(
          "dashboard.channels_overview.token_expires",
          time: distance_of_time_in_words(Time.current, channel.expires_at),
          default: "Token expires in about %{time}"
        )
      end
    end

    def channel_overview_edit_path(channel)
      case channel
      when Channel::Email then edit_channels_email_path(id: channel.id)
      when Channel::WebWidget then edit_channels_web_widget_path(id: channel.id)
      when Channel::ContactForm then edit_channels_contact_form_path(id: channel.id)
      when Channel::FacebookPage then edit_channels_facebook_path(id: channel.id)
      when Channel::Instagram then edit_channels_instagram_path(id: channel.id)
      when Channel::Whatsapp then edit_channels_whatsapp_path(id: channel.id)
      when Channel::Custom then edit_channels_custom_path(id: channel.id)
      end
    end

    def channel_overview_destroy_path(channel)
      case channel
      when Channel::Email then channels_email_path(id: channel.id)
      when Channel::WebWidget then channels_web_widget_path(id: channel.id)
      when Channel::ContactForm then channels_contact_form_path(id: channel.id)
      when Channel::FacebookPage then channels_facebook_path(id: channel.id)
      when Channel::Instagram then channels_instagram_path(id: channel.id)
      when Channel::Whatsapp then channels_whatsapp_path(id: channel.id)
      when Channel::Custom then channels_custom_path(id: channel.id)
      end
    end

    def channel_overview_policy(channel)
      policy_key = {
        "email" => :email_channel,
        "web_widget" => :web_widget_channel,
        "contact_form" => :contact_form_channel,
        "facebook" => :facebook_channel,
        "instagram" => :instagram_channel,
        "whatsapp" => :whatsapp_channel,
        "custom" => :custom_channel
      }.fetch(channel_overview_type(channel))

      policy(policy_key)
    end
  end
end
