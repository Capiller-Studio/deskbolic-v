# frozen_string_literal: true

module Dashboard
  module Channels
    class MobileWidgetController < DashboardController
      before_action :set_mobile_widget_channel, only: %i[show edit update destroy regenerate_secret test_push]
      before_action :authorize_mobile_widget_channel

      def index
        @mobile_widget_channels = current_account.with_shard do
          Channel::MobileWidget.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def show
        current_account.with_shard do
          @devices_count = @mobile_widget_channel.customer_devices.active.count
          @recent_devices = @mobile_widget_channel.customer_devices.order(last_seen_at: :desc).limit(10)
        end
      end

      def new
        @mobile_widget_channel = Channel::MobileWidget.new
        set_associations
      end

      def edit
        set_associations
      end

      def create
        unless current_account.within_limit?(:channels)
          redirect_to(channels_mobile_widget_index_path, alert: t("dashboard.mobile_widget_channels.limit_reached"))
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "mobile_widget",
          channel_params: mobile_widget_channel_params,
          current_account: current_account,
          current_user: current_user
        )

        if creator.call
          @mobile_widget_channel = creator.channel
          current_account.with_shard do
            assign_mobile_widget_flags(@mobile_widget_channel, mobile_widget_channel_params)
            @mobile_widget_channel.save!
          end
          redirect_to(edit_channels_mobile_widget_path(@mobile_widget_channel), notice: t("dashboard.mobile_widget_channels.created"))
        else
          @mobile_widget_channel = creator.channel || Channel::MobileWidget.new(mobile_widget_channel_params)
          set_associations
          render(:new, status: :unprocessable_entity)
        end
      end

      def update
        current_account.with_shard do
          params_to_update = mobile_widget_channel_params
          assign_mobile_widget_flags(@mobile_widget_channel, params_to_update)

          params_to_update = params_to_update.except(
            :anonymous_allowed, :secure_identity_enforced, :help_center_enabled,
            :pre_chat_form_enabled, :push_enabled, :custom_branding, :attachments_enabled
          )

          if @mobile_widget_channel.update(params_to_update)
            redirect_to(edit_channels_mobile_widget_path(@mobile_widget_channel), notice: t("dashboard.mobile_widget_channels.updated"))
          else
            set_associations
            render(:edit, status: :unprocessable_entity)
          end
        end
      end

      def destroy
        current_account.with_shard do
          @mobile_widget_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to(channels_mobile_widget_index_path, notice: t("dashboard.mobile_widget_channels.destroyed"), status: :see_other) }
          format.turbo_stream { redirect_to(channels_mobile_widget_index_path, notice: t("dashboard.mobile_widget_channels.destroyed"), status: :see_other) }
        end
      end

      def regenerate_secret
        current_account.with_shard do
          @mobile_widget_channel.regenerate_secret!
        end

        redirect_to(
          edit_channels_mobile_widget_path(@mobile_widget_channel, anchor: "identity"),
          notice: t("dashboard.mobile_widget_channels.secret_regenerated", default: "Secret regenerated successfully. Please update your backend servers.")
        )
      end

      def test_push
        success = false

        current_account.with_shard do
          device = @mobile_widget_channel.customer_devices.active.order(last_seen_at: :desc).first
          if device.nil?
            redirect_back(
              fallback_location: edit_channels_mobile_widget_path(@mobile_widget_channel),
              alert: t("dashboard.mobile_widget_channels.no_devices", default: "No active devices registered yet. Connect your mobile app first.")
            )
            return
          end

          payload = {
            title: "Deskbolic Test Push",
            body: "Push notification configured successfully! 🚀",
            badge: 1,
            data: { test: "true", channel_id: @mobile_widget_channel.id }
          }

          if device.apns?
            success = PushNotifications::ApnsSender.call(channel: @mobile_widget_channel, device: device, payload: payload)
          elsif device.fcm?
            success = PushNotifications::FcmSender.call(channel: @mobile_widget_channel, device: device, payload: payload)
          end
        end

        if success
          redirect_back(
            fallback_location: edit_channels_mobile_widget_path(@mobile_widget_channel),
            notice: t("dashboard.mobile_widget_channels.test_push_success", default: "Test push notification sent successfully!")
          )
        else
          redirect_back(
            fallback_location: edit_channels_mobile_widget_path(@mobile_widget_channel),
            alert: t("dashboard.mobile_widget_channels.test_push_failed", default: "Failed to send test push. Please verify your credentials and device tokens.")
          )
        end
      end

      private

      def set_mobile_widget_channel
        current_account.with_shard do
          @mobile_widget_channel = Channel::MobileWidget.find_by!(id: params[:id], account: current_account)
        end
      end

      def set_associations
        current_account.with_shard do
          @portals = current_account.portals
          @contact_forms = Channel::ContactForm.where(account: current_account)
          @email_channels = Channel::Email.where(account: current_account)
        end
      end

      def authorize_mobile_widget_channel
        authorize(:mobile_widget_channel)
      end

      def mobile_widget_channel_params
        permitted = params.expect(
          mobile_widget_channel: [
            :name, :portal_id, :default_locale, :pre_chat_form_id, :fallback_channel_id, :fallback_channel_type,
            :anonymous_allowed, :secure_identity_enforced, :help_center_enabled, :pre_chat_form_enabled,
            :push_enabled, :custom_branding, :attachments_enabled, :logo,
            :ios_bundle_id, :apns_key, :apns_key_id, :apns_team_id, :apns_environment,
            :android_package_name, :fcm_service_account,
            ui_configurations: [ :primary_color, :header_title_color ],
            configurations: [ :max_attachment_mb, :push_preview_mode ],
            primary_inbox_attributes: [
              :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id,
              :conversation_reply_template_id, :business_hour_group_id, :ai_classification,
              :ai_auto_labelling, :ai_thank_you_detection, :ai_agent_id,
              sla_policy_ids: [], user_ids: [], team_ids: []
            ],
            translations_attributes: [
              :id, :locale, :header_title, :welcome_title, :welcome_tagline, :reply_time_text,
              :pre_chat_title, :pre_chat_subtitle, :_destroy
            ]
          ]
        )

        result = permitted.slice(
          :name, :portal_id, :default_locale, :pre_chat_form_id, :fallback_channel_id, :fallback_channel_type,
          :anonymous_allowed, :secure_identity_enforced, :help_center_enabled, :pre_chat_form_enabled,
          :push_enabled, :custom_branding, :attachments_enabled, :logo,
          :ios_bundle_id, :apns_key, :apns_key_id, :apns_team_id, :apns_environment,
          :android_package_name, :fcm_service_account,
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

      def assign_mobile_widget_flags(mobile_widget_channel, params_to_update)
        mobile_widget_channel.anonymous_allowed = truthy_param?(params_to_update[:anonymous_allowed])
        mobile_widget_channel.secure_identity_enforced = truthy_param?(params_to_update[:secure_identity_enforced])
        mobile_widget_channel.help_center_enabled = truthy_param?(params_to_update[:help_center_enabled])
        mobile_widget_channel.pre_chat_form_enabled = truthy_param?(params_to_update[:pre_chat_form_enabled])
        mobile_widget_channel.push_enabled = truthy_param?(params_to_update[:push_enabled])
        mobile_widget_channel.custom_branding = truthy_param?(params_to_update[:custom_branding])
        mobile_widget_channel.attachments_enabled = params_to_update[:attachments_enabled].nil? || truthy_param?(params_to_update[:attachments_enabled])
      end

      def truthy_param?(value)
        value == "1" || value == true || value == "true"
      end
    end
  end
end
