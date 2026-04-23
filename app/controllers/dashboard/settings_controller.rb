# frozen_string_literal: true

module Dashboard
  class SettingsController < DashboardController
    def index
    end

    def canned_responses
      @canned_responses      = CannedResponse.where(account: current_account).all
      @canned_responses      = @canned_responses.where("name ILIKE ?",
"%#{params[:search]}%") if params[:search].present?
    end
    
    def office_timings; end
    
    def team_inboxes
      @teams = current_account.teams.all
    end
    
    def roles; end
    
    def messenger; end
    
    def tickets; end
  end
end
