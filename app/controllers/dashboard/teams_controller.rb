# frozen_string_literal: true

module Dashboard
  class TeamsController < DashboardController
    before_action :set_team, only: %i[show update destroy add_member remove_member]

    def index
      authorize(Team)
      @teams = current_account.teams.includes(:team_users).order(:name)
    end

    def show
      authorize(@team)
      @members = @team.team_users.includes(:user).order(:role, :created_at)
      @inboxes = @team.inboxes
    end

    def create
      authorize(Team)
      @team = Teams::CreateService.call(
        account: current_account,
        params: team_create_params
      )

      redirect_to(teams_path, notice: t(".created"))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      redirect_back(fallback_location: teams_path, alert: e.message)
    end

    def update
      authorize(@team)
      Teams::UpdateService.call(
        team: @team,
        params: team_update_params
      )

      redirect_to(teams_path, notice: t(".updated"))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      redirect_back(fallback_location: teams_path, alert: e.message)
    end

    def destroy
      authorize(@team)
      Teams::DestroyService.call(team: @team)

      redirect_to(teams_path, notice: "Team deleted successfully")
    rescue ActiveRecord::RecordNotSaved => e
      redirect_back(fallback_location: teams_path, alert: e.message)
    end

    def add_member
      authorize(@team, :update?)
      Teams::MemberService.call(
        team: @team,
        params: { action: :add, user_id: params[:user_id], role: params[:role] }
      )

      redirect_back(fallback_location: team_path(@team), notice: "Member added")
    rescue ActiveRecord::RecordInvalid => e
      redirect_back(fallback_location: team_path(@team), alert: e.message)
    end

    def remove_member
      authorize(@team, :update?)
      Teams::MemberService.call(
        team: @team,
        params: { action: :remove, user_id: params[:user_id] }
      )

      redirect_back(fallback_location: team_path(@team), notice: "Member removed")
    rescue ActiveRecord::RecordNotFound
      redirect_back(fallback_location: team_path(@team), alert: "Member not found")
    end

    private

    def set_team
      @team = current_account.teams.find(params[:id])
    end

    def team_create_params
      permitted = params.expect(
        team: [ :name, :description, :auto_assign, :avatar,
        user_ids: [], inbox_ids: [] ]
      )
      permitted[:lead_id] = params[:team][:lead_id] if params.dig(:team, :lead_id).present?
      permitted
    end

    def team_update_params
      permitted = params.expect(
        team: [ :name, :description, :auto_assign, :status, :avatar,
        user_ids: [], inbox_ids: [] ]
      )
      permitted[:lead_id] = params[:team][:lead_id] if params.dig(:team, :lead_id).present?
      permitted
    end
  end
end
