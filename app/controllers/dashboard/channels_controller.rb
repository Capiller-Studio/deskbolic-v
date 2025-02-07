# frozen_string_literal: true

module Dashboard
  class ChannelsController < DashboardController
    def index
      @em_channels = Channel::Email.where(account: current_account).all
      @fb_channels = Channel::FacebookPage.where(account: current_account).all
      @wa_channels = Channel::Whatsapp.where(account: current_account).all
    end
    
    def create
      response = Channels::ChannelCreator.call(channel_type: params[:channel_type], channel_params: params, current_account: current_account)
      
      if response
        redirect_to(request.referrer, notice: "Channel Created!")
      else
        redirect_to(request.referrer, alert: "Channel Already Exists!")
      end
    end
    
  end
end