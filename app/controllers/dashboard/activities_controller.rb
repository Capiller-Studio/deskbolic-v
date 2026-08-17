# frozen_string_literal: true

module Dashboard
  class ActivitiesController < DashboardController
    def append_activity
      @activity = Activity.where(account_id: current_account.id).find(params[:id])
      authorize(@activity)

      render(turbo_stream: turbo_stream.append(
        "message-frame",
        partial: "dashboard/activities/activity",
        locals: { activity: @activity }
      ))
    end
  end
end
