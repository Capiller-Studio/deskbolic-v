# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module Settings
    class GeneralController < DashboardController
      before_action :set_account
      before_action :authorize_owner, only: %i[update destroy]

      def show
        @is_owner = current_account_user&.owner?
      end

      def update
        if @account.update(general_params)
          redirect_to(settings_general_path, notice: t("dashboard.settings.general.notices.updated", default: "Workspace settings updated successfully."))
        else
          flash.now[:alert] = @account.errors.full_messages.to_sentence
          render(:show, status: :unprocessable_entity)
        end
      end

      def destroy
        unless current_account_user&.owner?
          redirect_to(settings_general_path, alert: t("dashboard.settings.general.alerts.owner_only", default: "Only workspace owners can request workspace deletion.")) and return
        end

        unless current_user.valid_password?(params[:password])
          redirect_to(settings_general_path, alert: t("dashboard.settings.general.alerts.incorrect_password", default: "Incorrect password. Workspace deletion cancelled.")) and return
        end

        if params[:identifier_confirmation].to_s.strip != @account.identifier
          redirect_to(settings_general_path, alert: t("dashboard.settings.general.alerts.identifier_mismatch", default: "Workspace identifier confirmation does not match.")) and return
        end

        account_to_deactivate = @account
        account_to_deactivate.deactivate_for_deletion!
        Activities::Recorder.call(trackable: account_to_deactivate, event_type: :deletion_requested, actor: current_user, account: account_to_deactivate)

        remaining_accounts = current_user.accounts.active.where.not(id: account_to_deactivate.id)

        notice_msg = t("dashboard.settings.general.notices.deletion_requested", default: "Workspace deletion requested. The workspace has been deactivated.")
        if remaining_accounts.exists?
          redirect_to(
            workspaces_url(subdomain: ""),
            allow_other_host: true,
            notice: notice_msg
          )
        else
          sign_out(current_user)
          redirect_to(
            new_user_session_path,
            notice: notice_msg
          )
        end
      end

      private

      def set_account
        @account = current_account
      end

      def authorize_owner
        return if current_account_user&.owner?

        redirect_to(settings_general_path, alert: t("dashboard.settings.general.alerts.unauthorized", default: "You are not authorized to perform this action."))
      end

      def general_params
        params.expect(account: %i[name timezone locale])
      end
    end
  end
end
