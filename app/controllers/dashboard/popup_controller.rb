# frozen_string_literal: true

module Dashboard
  class PopupController < DashboardController
    def modal_popup
      @popup_view = params[:step]

      if @popup_view == "_team_modal"
        if params[:id].present?
          @team = current_account.teams.find(params[:id])
        else
          @team = current_account.teams.new
        end
        @users = current_account.users.order(:first_name, :email)
        @inboxes = current_account.inboxes.order(:name)
      end

      render("#{@popup_view}", layout: false)
    end
  end
end
