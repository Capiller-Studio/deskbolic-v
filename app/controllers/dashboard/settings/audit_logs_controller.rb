# frozen_string_literal: true

module Dashboard
  module Settings
    class AuditLogsController < DashboardController
      def index
        authorize :audit_log, :index?
        
        # Respect the account's plan limit for audit log retention
        @pagy, @activities = pagy(
          Activity.where(account: current_account).latest.retention_visible_for(current_account),
          limit: 20
        )
      end

      def revert
        authorize :audit_log, :revert?

        @activity = Activity.where(account: current_account).find(params[:id])
        
        mode = params[:mode] == 'rollback' ? :rollback : :undo
        service = Activities::RevertService.new(activity: @activity, mode: mode)

        if service.call
          redirect_to settings_audit_logs_path, notice: t("audit_logs.revert_success", default: "Activity successfully reverted.")
        else
          redirect_to settings_audit_logs_path, alert: t("audit_logs.revert_failed", default: "Failed to revert activity.")
        end
      end
    end
  end
end
