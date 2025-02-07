# frozen_string_literal: true

module Dashboard
  class InboxesController < DashboardController
    def create
      Inboxes::InboxCreator.call(inbox_type: params[:inbox_type], inbox_params: params,
current_account: current_account)

      redirect_back(fallback_location: root_path, notice: "Inbox Created!")
    end
  end
end
