# frozen_string_literal: true

module Dashboard
  module SettingsHelper
    CHANNEL_TYPE_KEYS = {
      "Channel::Email" => "email",
      "Channel::WebWidget" => "web_widget",
      "Channel::MobileWidget" => "mobile_widget",
      "Channel::ContactForm" => "contact_form",
      "Channel::FacebookPage" => "facebook",
      "Channel::Instagram" => "instagram",
      "Channel::Whatsapp" => "whatsapp",
      "Channel::Custom" => "custom"
    }.freeze

    CHANNEL_TYPE_LABELS = {
      "email" => "Email",
      "web_widget" => "Web Widget",
      "mobile_widget" => "Mobile App (SDK)",
      "contact_form" => "Contact Form",
      "facebook" => "Facebook",
      "instagram" => "Instagram",
      "whatsapp" => "WhatsApp",
      "custom" => "Custom"
    }.freeze

    CHANNEL_TYPE_ICONS = {
      "email" => "email.svg",
      "web_widget" => "widget.svg",
      "mobile_widget" => "mobile_widget.svg",
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
      t("dashboard.channels_overview.types.#{type}", default: CHANNEL_TYPE_LABELS.fetch(type))
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
      when Channel::MobileWidget
        channel.identifier
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
      version_param = channel.respond_to?(:updated_at) && channel.updated_at.present? ? "?v=#{channel.updated_at.to_i}" : ""
      %(<script src="#{widget_app_url}/#{channel_path}/#{account.id}/#{channel.id}/embed.js#{version_param}"></script>)
    end

    def channel_overview_logo(channel)
      return channel.avatar_url if channel.respond_to?(:avatar_url) && channel.avatar_url.present?
      return channel.scaled_logo if channel.is_a?(Channel::WebWidget) && channel.logo.attached?

      nil
    end

    def channel_overview_status(channel)
      return "disconnected" if channel.respond_to?(:reauthorization_required?) && channel.reauthorization_required?
      return "disconnected" if channel.respond_to?(:token_expired?) && channel.token_expired?
      return "active" if channel.respond_to?(:active?) && channel.active?

      "disconnected"
    end

    def channel_overview_connected?(channel)
      channel_overview_status(channel) == "active"
    end

    def channel_overview_token_message(channel)
      return unless channel.is_a?(Channel::Instagram) && channel.expires_at.present?

      if channel.token_expired?
        t(
          "dashboard.channels_overview.token_expired",
          time: time_ago_in_words(account_time(channel.expires_at)),
          default: "Token expired %{time} ago"
        )
      else
        t(
          "dashboard.channels_overview.token_expires",
          time: distance_of_time_in_words(Time.current, account_time(channel.expires_at)),
          default: "Token expires in about %{time}"
        )
      end
    end

    def channel_overview_token_expiration(channel)
      return t("general.not_available", default: "Not available") unless channel.respond_to?(:expires_at) && channel.expires_at.present?

      l(account_time(channel.expires_at), format: :long)
    end

    def channel_show_overview_locals(channel)
      connected = channel_overview_connected?(channel)

      {
        platform_icon: "inboxes.svg",
        platform_name: channel_overview_type_label(channel),
        overview_items: channel_show_overview_items(channel),
        connected: connected,
        status_label: channel_show_status_label(channel),
        meta_item: channel_show_overview_meta(channel)
      }
    end

    def channel_show_sections(channel, account)
      sections = [
        {
          icon: "info.svg",
          title: t("dashboard.channels.edit.channel_information", default: "Channel Information"),
          items: channel_show_information_items(channel)
        }
      ]

      configuration_items = channel_show_configuration_items(channel)
      if configuration_items.any?
        sections << {
          icon: "settings.svg",
          title: t("dashboard.channels.show.configuration", default: "Channel Configuration"),
          items: configuration_items
        }
      end

      if (inbox = channel.primary_inbox)
        sections << {
          icon: "envelope.svg",
          title: t("dashboard.channels.edit.inbox_settings", default: "Inbox Settings"),
          items: channel_show_inbox_items(inbox)
        }
        sections << {
          icon: "clock.svg",
          title: t("dashboard.channels.show.routing_and_service", default: "Routing & Service"),
          description: t("dashboard.channels.show.routing_description", default: "Business hours and response targets for this inbox."),
          items: channel_show_routing_items(inbox, account)
        }
      end

      sections
    end

    def channel_show_sidebar_page(channel)
      "#{channel_overview_type(channel).dasherize}-channels"
    end

    def channel_show_description(channel)
      t(
        "dashboard.channels.show.description",
        type: channel_overview_type_label(channel),
        default: "Review this %{type} connection and its inbox configuration."
      )
    end

    def channel_show_details_partial(channel)
      return unless %w[email web_widget contact_form whatsapp custom mobile_widget].include?(channel_overview_type(channel))

      "dashboard/channels/#{channel_overview_type(channel)}/show_details"
    end

    def channel_show_aside_partial(channel)
      return unless %w[web_widget mobile_widget].include?(channel_overview_type(channel))

      "dashboard/channels/#{channel_overview_type(channel)}/show_aside"
    end

    def channel_show_preview_url(channel, account)
      preview_type = channel.is_a?(Channel::WebWidget) ? "w" : "f"
      widget_app_url = (ENV["WIDGET_APP_URL"].presence || "https://widget.deskbolic.com").delete_suffix("/")
      "#{widget_app_url}/#{preview_type}/#{account.id}/#{channel.id}?preview=true"
    end

    def channel_show_theme_color(channel)
      color = channel.respond_to?(:theme_color) ? channel.theme_color.to_s : ""
      color.match?(/\A#[0-9a-f]{3,8}\z/i) ? color : "#0f172a"
    end

    def channel_show_position(channel, default: "right")
      position = channel.respond_to?(:position) ? channel.position.to_s : ""
      %w[left center right].include?(position) ? position : default
    end

    def channel_show_position_label(channel, default: "right")
      position = channel_show_position(channel, default: default)
      t("dashboard.channels.show.positions.#{position}", default: position.humanize)
    end

    def channel_show_status_label(channel)
      if channel.respond_to?(:reauthorization_required?) && channel.reauthorization_required?
        return t("dashboard.channels.show.reauthorization_required", default: "Re-authorization needed")
      end

      t(
        "dashboard.channels_overview.status.#{channel_overview_status(channel)}",
        default: channel_overview_status(channel).humanize
      )
    end

    def channel_show_reconnect_path(channel)
      case channel
      when Channel::FacebookPage then reconnect_channels_facebook_path(id: channel.id)
      when Channel::Instagram then oauth_authorize_channels_instagram_index_path
      when Channel::Whatsapp then reconnect_channels_whatsapp_path(id: channel.id)
      end
    end

    def channel_show_reconnect_data(channel)
      channel.is_a?(Channel::Instagram) ? { turbo: false } : { turbo_method: :post }
    end

    def channel_show_danger_description(channel)
      t(
        "dashboard.channels.show.disconnect_description",
        type: channel_overview_type_label(channel),
        default: "Disconnecting this %{type} channel will remove its inbox and stop new messages. Existing conversations will be preserved."
      )
    end

    def channel_show_delete_confirmation(channel)
      locale_key = channel_overview_type(channel)
      action_key = channel.is_a?(Channel::ContactForm) ? "confirm_delete" : "delete_confirm"
      t(
        "dashboard.#{locale_key}_channels.index.#{action_key}",
        name: channel_overview_name(channel),
        default: "Disconnect %{name}?"
      )
    end

    def channel_show_information_items(channel)
      items = [ channel_show_item(t("dashboard.channels.edit.channel_name", default: "Channel Name"), channel_overview_name(channel)) ]

      items.concat(
        case channel
        when Channel::Email
          [
            channel_show_item(t("dashboard.channels.show.email_address", default: "Email Address"), channel.email)
          ]
        when Channel::WebWidget
          [
            channel_show_item(t("dashboard.channels.show.allowed_domains", default: "Allowed Domains"), Array(channel.allowed_hosts).to_sentence, wide: true),
            channel_show_item(t("dashboard.channels.show.default_locale", default: "Default Locale"), channel.default_locale&.upcase)
          ]
        when Channel::ContactForm
          [
            channel_show_item(t("dashboard.channels.show.channel_type", default: "Channel Type"), t("dashboard.channels.show.embedded_contact_form", default: "Embedded contact form")),
            channel_show_item(t("dashboard.channels.show.outbound_channel", default: "Outbound Channel"), channel.outbound_channel&.name),
            channel_show_item(t("dashboard.channels.show.redirect_url", default: "Success Redirect URL"), channel.submit_redirect_url, wide: true)
          ]
        when Channel::FacebookPage
          [ channel_show_item(t("dashboard.channels.edit.page_id", default: "Page ID"), channel.page_identifier) ]
        when Channel::Instagram
          [
            channel_show_item(t("dashboard.channels.edit.username", default: "Username"), channel_overview_identifier(channel)),
            channel_show_item(t("dashboard.channels.show.instagram_id", default: "Instagram Account ID"), channel.instagram_id),
            channel_show_item(t("dashboard.channels.edit.token_expires", default: "Token Expires"), channel_overview_token_expiration(channel))
          ]
        when Channel::Whatsapp
          [
            channel_show_item(t("dashboard.channels.show.phone_number", default: "Phone Number"), channel.full_phone_number),
            channel_show_item(t("dashboard.channels.show.phone_number_id", default: "Phone Number ID"), channel.phone_number_id),
            channel_show_item(t("dashboard.channels.show.business_account_id", default: "Business Account ID"), channel.business_account_id)
          ]
        when Channel::Custom
          [
            channel_show_item(t("dashboard.channels.edit.identifier", default: "Identifier"), channel.identifier),
            channel_show_item(t("dashboard.channels.show.description_label", default: "Description"), channel.description, wide: true)
          ]
        else
          []
        end
      )
    end

    def channel_show_configuration_items(channel)
      case channel
      when Channel::Email
        [
          channel_show_boolean_item(t("dashboard.email_channels.form.enable_smtp", default: "SMTP Sending"), channel.smtp_enabled?),
          channel_show_boolean_item(t("dashboard.email_channels.form.enable_imap", default: "IMAP Receiving"), channel.imap_enabled?),
          channel_show_item(t("dashboard.email_channels.form.smtp_address", default: "SMTP Server"), channel.smtp_configurations&.dig("address")),
          channel_show_item(t("dashboard.email_channels.form.imap_address", default: "IMAP Server"), channel.imap_configurations&.dig("address"))
        ]
      when Channel::WebWidget
        [
          channel_show_boolean_item(t("dashboard.channels.show.anonymous_visitors", default: "Anonymous Visitors"), channel.anonymous_allowed?),
          channel_show_boolean_item(t("dashboard.channels.show.help_center_enabled", default: "Help Center"), channel.help_center_enabled?),
          channel_show_boolean_item(t("dashboard.channels.show.pre_chat_form", default: "Pre-chat Form"), channel.pre_chat_form_enabled?),
          channel_show_boolean_item(t("dashboard.channels.show.secure_identity", default: "Secure Identity"), channel.secure_identity_enforced?),
          channel_show_boolean_item(t("dashboard.channels.show.custom_branding", default: "Custom Branding"), channel.custom_branding?)
        ]
      when Channel::ContactForm
        [
          channel_show_boolean_item(t("dashboard.channels.show.login_required", default: "Login Required"), channel.require_login?),
          channel_show_boolean_item(t("dashboard.channels.show.attachments", default: "Attachments"), channel.allow_attachments?),
          channel_show_boolean_item(t("dashboard.channels.show.confirmation_email", default: "Confirmation Email"), channel.send_confirmation_email?),
          channel_show_boolean_item(t("dashboard.channels.show.spam_protection", default: "Spam Protection"), channel.spam_protection_enabled?)
        ]
      when Channel::Whatsapp
        [
          channel_show_item(t("dashboard.channels.show.connection_method", default: "Connection Method"), channel.provider_embedded_signup? ? t("dashboard.channels.show.embedded_signup", default: "Meta Embedded Signup") : t("dashboard.channels.show.manual_setup", default: "Manual setup"))
        ]
      else
        []
      end
    end

    def channel_show_inbox_items(inbox)
      [
        channel_show_item(t("dashboard.channels.show.inbox_name", default: "Inbox Name"), inbox.name),
        channel_show_boolean_item(t("dashboard.channels.show.csat_status", default: "CSAT Survey"), inbox.csat_survey_enabled?),
        channel_show_item(t("dashboard.channels.edit.select_csat_survey", default: "Survey Template"), inbox.csat_survey&.name || t("forms.options.default_system_survey")),
        channel_show_boolean_item(t("dashboard.channels.show.auto_assignment", default: "Automatic Assignment"), inbox.auto_assign?),
        channel_show_item(t("forms.labels.custom_reply_template", default: "Reply Template"), inbox.conversation_reply_template&.name || t("forms.options.default_email_view")),
        channel_show_item(t("dashboard.channels.show.reopen_window", default: "Conversation Reopen Window"), channel_show_reopen_window(inbox.reopen_window_seconds))
      ]
    end

    def channel_show_reopen_window(seconds)
      return t("forms.options.never_always_create_new", default: "Never — always create a new conversation") if seconds.to_i.zero?

      distance_of_time_in_words(seconds.to_i)
    end

    def channel_show_routing_items(inbox, account)
      business_hours = account.business_hour_groups.find_by(id: inbox.business_hour_group_id)
      sla_names = inbox.sla_policies.order(:name).pluck(:name).to_sentence

      [
        channel_show_item(t("forms.labels.business_hours"), business_hours&.name || t("dashboard.channels.edit.always_available", default: "Your team is available 24/7")),
        channel_show_item(t("forms.labels.sla_policies"), sla_names.presence || t("dashboard.channels.edit.none_selected", default: "None selected"))
      ]
    end

    def channel_show_overview_items(channel)
      label, icon =
        case channel
        when Channel::Email then [ t("dashboard.channels.show.email_address", default: "Email Address"), "envelope.svg" ]
        when Channel::FacebookPage then [ t("dashboard.channels.edit.page_id", default: "Page ID"), "flag.svg" ]
        when Channel::Instagram then [ t("dashboard.channels.edit.username", default: "Username"), "users.svg" ]
        when Channel::Whatsapp then [ t("dashboard.channels.show.phone_number", default: "Phone Number"), "whatsapp.svg" ]
        else [ t("dashboard.channels.show.identifier", default: "Identifier"), "info.svg" ]
        end

      [ { icon: icon, label: label, value: channel_overview_identifier(channel) } ]
    end

    def channel_show_overview_meta(channel)
      if channel.respond_to?(:expires_at) && channel.expires_at.present?
        {
          icon: "timer.svg",
          label: t("dashboard.channels.edit.token_expires", default: "Token Expires"),
          value: channel_overview_token_expiration(channel)
        }
      else
        {
          icon: "clock.svg",
          label: t("dashboard.channels.edit.created", default: "Created"),
          value: t("dashboard.channels.edit.created_ago", time: time_ago_in_words(account_time(channel.created_at)), default: "About %{time} ago")
        }
      end
    end

    def channel_show_item(label, value, wide: false)
      {
        label: label,
        value: value.presence || t("general.not_available", default: "Not available"),
        wide: wide
      }
    end

    def channel_show_boolean_item(label, enabled)
      {
        label: label,
        value: enabled ? t("general.enabled", default: "Enabled") : t("general.disabled", default: "Disabled"),
        enabled: enabled
      }
    end

    def channel_show_boolean_label(enabled)
      enabled ? t("general.enabled", default: "Enabled") : t("general.disabled", default: "Disabled")
    end

    def channel_show_configuration_enabled?(value, default: true)
      return default if value.nil?

      [ false, "false", 0, "0" ].exclude?(value)
    end

    def channel_overview_index_path(channel)
      case channel
      when Channel::Email then channels_email_index_path
      when Channel::WebWidget then channels_web_widget_index_path
      when Channel::MobileWidget then channels_mobile_widget_index_path
      when Channel::ContactForm then channels_contact_form_index_path
      when Channel::FacebookPage then channels_facebook_index_path
      when Channel::Instagram then channels_instagram_index_path
      when Channel::Whatsapp then channels_whatsapp_index_path
      when Channel::Custom then channels_custom_index_path
      end
    end

    def channel_overview_edit_path(channel)
      case channel
      when Channel::Email then edit_channels_email_path(id: channel.id)
      when Channel::WebWidget then edit_channels_web_widget_path(id: channel.id)
      when Channel::MobileWidget then edit_channels_mobile_widget_path(id: channel.id)
      when Channel::ContactForm then edit_channels_contact_form_path(id: channel.id)
      when Channel::FacebookPage then edit_channels_facebook_path(id: channel.id)
      when Channel::Instagram then edit_channels_instagram_path(id: channel.id)
      when Channel::Whatsapp then edit_channels_whatsapp_path(id: channel.id)
      when Channel::Custom then edit_channels_custom_path(id: channel.id)
      end
    end

    def channel_overview_show_path(channel)
      case channel
      when Channel::Email then channels_email_path(id: channel.id)
      when Channel::WebWidget then channels_web_widget_path(id: channel.id)
      when Channel::MobileWidget then channels_mobile_widget_path(id: channel.id)
      when Channel::ContactForm then channels_contact_form_path(id: channel.id)
      when Channel::FacebookPage then channels_facebook_path(id: channel.id)
      when Channel::Instagram then channels_instagram_path(id: channel.id)
      when Channel::Whatsapp then channels_whatsapp_path(id: channel.id)
      when Channel::Custom then channels_custom_path(id: channel.id)
      end
    end

    def channel_overview_destroy_path(channel)
      case channel
      when Channel::Email then channels_email_path(id: channel.id)
      when Channel::WebWidget then channels_web_widget_path(id: channel.id)
      when Channel::MobileWidget then channels_mobile_widget_path(id: channel.id)
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
        "mobile_widget" => :mobile_widget_channel,
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
