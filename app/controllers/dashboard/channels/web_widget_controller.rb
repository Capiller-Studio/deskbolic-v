# frozen_string_literal: true

module Dashboard
  module Channels
    class WebWidgetController < DashboardController
    before_action :set_web_widget_channel, only: %i[show edit update destroy]
    before_action :authorize_web_widget_channel

    def index
      @web_widget_channels = current_account.with_shard do
        Channel::WebWidget.where(account: current_account).includes(:inboxes).order(created_at: :desc)
      end
    end

    def show; end

    def new
      @web_widget_channel = Channel::WebWidget.new
      set_associations
    end

    def edit
      set_associations
    end
    def create
      unless current_account.within_limit?(:channels)
        redirect_to(channels_web_widget_index_path, alert: t("dashboard.web_widget_channels.limit_reached"))
        return
      end

      creator = ::Channels::ChannelCreator.new(
        channel_type: "web_widget",
        channel_params: web_widget_channel_params,
        current_account: current_account,
        current_user: current_user
      )

      if creator.call
        @web_widget_channel = creator.channel
        current_account.with_shard do
          assign_web_widget_flags(@web_widget_channel, web_widget_channel_params)
          @web_widget_channel.save!
        end
        redirect_to(edit_channels_web_widget_path(@web_widget_channel), notice: t("dashboard.web_widget_channels.created"))
      else
        @web_widget_channel = creator.channel || Channel::WebWidget.new(web_widget_channel_params)
        set_associations
        render(:new, status: :unprocessable_entity)
      end
    end


    def update
      current_account.with_shard do
        params_to_update = web_widget_channel_params
        assign_web_widget_flags(@web_widget_channel, params_to_update)

        # Remove flags from params before calling update
        params_to_update = params_to_update.except(:anonymous_allowed, :help_center_enabled, :pre_chat_form_enabled, :secure_identity_enforced, :custom_branding)

        if @web_widget_channel.update(params_to_update)
          redirect_to(channels_web_widget_index_path, notice: t("dashboard.web_widget_channels.updated"))
        else
          set_associations
          render(:edit, status: :unprocessable_entity)
        end
      end
    end

    def destroy
      current_account.with_shard do
        @web_widget_channel.destroy
      end
      current_account.decrement_usage!(:channels)

      respond_to do |format|
        format.html { redirect_to(channels_web_widget_index_path, notice: t("dashboard.web_widget_channels.destroyed")) }
        format.turbo_stream { render(turbo_stream: turbo_stream.remove(@web_widget_channel)) }
      end
    end

    private

    def set_web_widget_channel
      current_account.with_shard do
        @web_widget_channel = Channel::WebWidget.find_by!(id: params[:id], account: current_account)
      end
    end

    def set_associations
      current_account.with_shard do
        @portals = current_account.portals
        @contact_forms = Channel::ContactForm.where(account: current_account)
        @email_channels = Channel::Email.where(account: current_account)
      end
    end

    def authorize_web_widget_channel
      authorize(:web_widget_channel)
    end

    def web_widget_channel_params
      permitted = params.expect(
        web_widget_channel: [ :name, :portal_id, :default_locale, :pre_chat_form_id, :fallback_channel_id, :fallback_channel_type,
        :anonymous_allowed, :help_center_enabled, :pre_chat_form_enabled, :secure_identity_enforced, :custom_branding, :logo, :launcher_icon,
        :theme_color, :position, :footer_text,
        allowed_hosts: [],
        ui_configurations: [ :theme_color, :position, :footer_text ],
        configurations: [],
        primary_inbox_attributes: [ :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id, :conversation_reply_template_id, :business_hour_group_id, :ai_classification, :ai_auto_labelling, :ai_thank_you_detection, :ai_agent_id, sla_policy_ids: [], user_ids: [], team_ids: [] ],
        translations_attributes: [ :id, :locale, :welcome_title, :welcome_tagline, :launcher_text, :reply_time_text, :pre_chat_title, :pre_chat_subtitle, :_destroy ] ]
      )

      result = permitted.slice(
        :name, :allowed_hosts, :portal_id, :default_locale, :pre_chat_form_id, :fallback_channel_id, :fallback_channel_type,
        :anonymous_allowed, :help_center_enabled, :pre_chat_form_enabled, :secure_identity_enforced, :custom_branding, :logo, :launcher_icon,
        :theme_color, :position, :footer_text,
        :primary_inbox_attributes, :translations_attributes
      ).to_h

      result[:pre_chat_form_enabled] = result[:pre_chat_form_id].present?

      if permitted[:ui_configurations].present?
        result[:ui_configurations] = permitted[:ui_configurations].to_h.compact_blank
      end

      if permitted[:configurations].present?
        result[:configurations] = permitted[:configurations].to_h.compact_blank
      end

      result
    end

    def assign_web_widget_flags(web_widget_channel, params_to_update)
      # These are bit flags on the channel model, so normalize form checkbox values explicitly.
      web_widget_channel.anonymous_allowed = truthy_param?(params_to_update[:anonymous_allowed])
      web_widget_channel.help_center_enabled = truthy_param?(params_to_update[:help_center_enabled])
      web_widget_channel.pre_chat_form_enabled = truthy_param?(params_to_update[:pre_chat_form_enabled])
      web_widget_channel.secure_identity_enforced = truthy_param?(params_to_update[:secure_identity_enforced])
      web_widget_channel.custom_branding = truthy_param?(params_to_update[:custom_branding])
    end

    def truthy_param?(value)
      value == "1" || value == true || value == "true"
    end
    end
  end
end
