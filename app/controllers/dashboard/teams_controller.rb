# frozen_string_literal: true

module Dashboard
  class TeamsController < DashboardController
    def create
      @team = current_account.teams.new(team_params)
      @team.save!
      
      redirect_back(fallback_location: :back)
    end

    def team_params
      params.require(:team).permit(
        :name, :avatar
      )
    end
  end
end
