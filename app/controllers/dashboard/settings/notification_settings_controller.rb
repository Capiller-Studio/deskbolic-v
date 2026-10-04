# frozen_string_literal: true

module Dashboard
  module Settings
    class NotificationSettingsController < DashboardController
      def show
        edit
        render(:edit)
      end

      def edit
        @notification_setting = current_user.notification_settings.find_or_create_by!(account: current_account)
        authorize(@notification_setting)
      end

      def update
        @notification_setting = current_user.notification_settings.find_or_create_by!(account: current_account)
        authorize(@notification_setting)

        if @notification_setting.update(notification_setting_params)
          redirect_to(edit_settings_notifications_path, notice: t("notification_settings.updated", default: "Notification settings updated successfully."))
        else
          render(:edit, status: :unprocessable_entity)
        end
      end

      private

      def notification_setting_params
        # Extract boolean values from parameters to assign to bitmask flags
        params.expect(
          notification_setting: [ :email_conversation_created, :email_conversation_assigned, :email_conversation_resolved,
          :email_sla_breached, :email_message_created, :email_conversation_mention,
          :email_subscription_created, :email_subscription_renewed, :email_subscription_cancelled,
          :email_trial_expiring, :email_payment_failed, :email_limit_approaching,
          :email_limit_reached, :email_team_assigned,

          :push_conversation_created, :push_conversation_assigned, :push_conversation_resolved,
          :push_sla_breached, :push_message_created, :push_conversation_mention,
          :push_subscription_created, :push_subscription_renewed, :push_subscription_cancelled,
          :push_trial_expiring, :push_payment_failed, :push_limit_approaching,
          :push_limit_reached, :push_team_assigned ]
        )
      end
    end
  end
end
