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
      true
    rescue
      false
    end

    private

    def create_channel
      send("#{channel_type.underscore.parameterize(separator: "_")}_channel")
    end

    def email_channel
      existing_channel = Channel::Email.find_by(account: current_account, email: channel_params[:email])
      
      raise("Invalid Record") if existing_channel
      
      channel = Channel::Email.create!(
        name: channel_params[:name],
        email: channel_params[:email],
        account: current_account
      )
      
      channel.inboxes.create!(
        name: channel_params[:name],
        account: current_account
      )
    end

    def facebook_page_channel
      existing_channel = Channel::FacebookPage.find_by(account: current_account, page_identifier: JSON.parse(channel_params[:page_data])["id"])
      
      raise("Invalid Record") if existing_channel
      
      channel = Channel::FacebookPage.create!(
        name: channel_params[:name],  
        access_token: JSON.parse(channel_params[:page_data])["access_token"], 
        page_identifier: JSON.parse(channel_params[:page_data])["id"],
        account: current_account
      )
      
      channel.inboxes.create!(
        name: JSON.parse(channel_params[:page_data])["name"],
        account: current_account
      )
    end  
  end
end