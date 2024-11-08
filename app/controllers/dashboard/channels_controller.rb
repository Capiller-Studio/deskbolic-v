# frozen_string_literal: true

module Dashboard
  class ChannelsController < DashboardController
    def index
      @em_channels = Channel::Email.where(account: current_account).all
      @fb_channels = Channel::FacebookPage.where(account: current_account).all
    end
    
    def create
      Channels::ChannelCreator.call(channel_type: params[:channel_type], channel_params: params, current_account: current_account)
      
      redirect_back(fallback_location: root_path, notice: "Channel Created!")
    end
    
  end
end