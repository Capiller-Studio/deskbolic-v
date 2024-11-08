# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  class ChannelCreator < ApplicationService
    attr_accessor :channel_type, :channel_params, :current_account

    def initialize(channel_type:, channel_params:, current_account:)
      self.channel_type      = channel_type
      self.channel_params    = channel_params
      self.current_account   = current_account
    end

    def call
      create_channel if channel_type.present?
    end

    private

    def create_channel
      send("#{channel_type.underscore.parameterize(separator: "_")}_channel")
    end

    def email_channel
      Channel::Email.create!(
        name: channel_params[:name],
        email: channel_params[:email],
        account: current_account
      )
    end

    def facebook_page_channel
      Channel::FacebookPage.create!(
        name: channel_params[:name],  
        access_token: channel_params[:access_token], 
        page_identifier: channel_params[:page_identifier],
        account: current_account
      )
    end  
  end
end