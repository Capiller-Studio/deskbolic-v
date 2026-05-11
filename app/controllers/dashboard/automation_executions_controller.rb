# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class AutomationExecutionsController < DashboardController
    def index
      authorize(Automation)

      @executions = current_account.automation_executions
                                   .includes(:executable)
                                   .recent

      @executions = @executions.where(status: params[:status]) if params[:status].present?
      @executions = @executions.where(triggered_by: params[:triggered_by]) if params[:triggered_by].present?

      if params[:executable_type].present? && params[:executable_id].present?
        @executions = @executions.where(executable_type: params[:executable_type], executable_id: params[:executable_id])
      end

      @pagy, @executions = pagy(@executions, limit: 25)
    end
  end
end
