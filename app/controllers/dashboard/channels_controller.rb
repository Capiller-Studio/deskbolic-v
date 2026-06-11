# frozen_string_literal: true

module Dashboard
  class ChannelsController < DashboardController
    def index
      @inboxes = current_account.inboxes.all
      @teams = current_account.teams.includes(:team_users).order(:name)
      @team_users = @teams.flat_map(&:team_users).reject { |tu| tu.user_id == current_user.id }.uniq(&:user_id)
    end

    def create
      creator = Channels::ChannelCreator.new(
        channel_type: params[:channel_type],
        channel_params: params,
        current_account: current_account
      )

      if creator.call
        redirect_to(request.referer, notice: "Channel Created!")
      else
        error_msg = creator.channel&.errors&.full_messages&.join(', ') || "Failed to create channel"
        redirect_to(request.referer, alert: error_msg)
      end
    end
  end
end
