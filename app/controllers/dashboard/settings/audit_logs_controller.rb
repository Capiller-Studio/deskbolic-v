# frozen_string_literal: true

module Dashboard
  module Settings
    class AuditLogsController < DashboardController
      def index
        authorize(:audit_log, :index?)

        @from_date = parsed_date(params[:from])
        @to_date = parsed_date(params[:to])
        # Respect the account's plan limit for audit log retention
        activities = Activity.where(account: current_account).latest.retention_visible_for(current_account)
        activities = activities.where(created_at: @from_date.beginning_of_day..@to_date.end_of_day) if @from_date && @to_date
        activities = activities.where(actor_type: "User", actor_id: params[:actor_id]) if params[:actor_id].present?

        @per_page = [ 10, 20, 50 ].include?(params[:per_page].to_i) ? params[:per_page].to_i : 10
        @pagy, @activities = pagy(activities, items: @per_page)
      end

      def revert
        authorize(:audit_log, :revert?)

        @activity = Activity.where(account: current_account).find(params[:id])

        mode = params[:mode] == "rollback" ? :rollback : :undo
        service = Activities::RevertService.new(activity: @activity, mode: mode)

        if service.call
          redirect_to(settings_audit_logs_path, notice: t("audit_logs.revert_success", default: "Activity successfully reverted."))
        else
          redirect_to(settings_audit_logs_path, alert: t("audit_logs.revert_failed", default: "Failed to revert activity."))
        end
      end

      private

      def parsed_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
    end
  end
end
