# frozen_string_literal: true

module Dashboard
  class ChannelsController < DashboardController
    def index
      redirect_to(conversations_path)
    end

    def create
      creator = Channels::ChannelCreator.new(
        channel_type: params[:channel_type],
        channel_params: params,
        current_account: current_account,
        current_user: current_user
      )

      if creator.call
        redirect_to(request.referer, notice: "Channel Created!")
      else
        error_msg = creator.channel&.errors&.full_messages&.join(", ") || "Failed to create channel"
        redirect_to(request.referer, alert: error_msg)
      end
    end
  end
end
