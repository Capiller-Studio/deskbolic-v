# frozen_string_literal: true

module Dashboard
  module Channels
    class FacebookController < DashboardController
    before_action :set_facebook_channel, only: %i[edit update destroy reconnect]
    before_action :authorize_facebook_channel

    def index
      @facebook_channels = current_account.with_shard do
        Channel::FacebookPage.where(account: current_account).includes(:inboxes).order(created_at: :desc)
      end
    end

    def new
      @facebook_channel = Channel::FacebookPage.new
      @facebook_app_id = Rails.application.credentials.dig(:channels, :facebook, :app_id)
    end

    # POST /facebook_channels/callback
    # Receives the short-lived token from the Facebook JS SDK login and exchanges it
    # for a long-lived user token + list of pages with permanent page access tokens.
    def callback
      result = ::Channels::FacebookPages::TokenExchangeService.call(
        short_lived_token: params[:access_token],
        account: current_account
      )

      @pages = result[:pages]
      @user_access_token = result[:user_access_token]

      # Filter out pages already connected to this account
      connected_page_ids = current_account.with_shard do
        Channel::FacebookPage.where(account: current_account).pluck(:page_identifier)
      end
      @pages.each { |p| p[:already_connected] = connected_page_ids.include?(p[:id]) }

      respond_to do |format|
        format.turbo_stream
        format.html { render(:new) }
      end
    rescue StandardError => e
      Rails.logger.error("Facebook token exchange failed: #{e.message}")
      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.update("page-selector",
            partial: "dashboard/channels/facebook/callback_error",
            locals: { error: t("dashboard.facebook_channels.callback_error") }))
        end
        format.html { redirect_to(new_channels_facebook_path, alert: t("dashboard.facebook_channels.callback_error")) }
      end
    end

    def edit; end
    def create
      unless current_account.within_limit?(:channels)
        redirect_to(channels_facebook_index_path, alert: t("dashboard.facebook_channels.limit_reached"))
        return
      end

      creator = ::Channels::ChannelCreator.new(
        channel_type: "facebook_page",
        channel_params: facebook_channel_create_params,
        current_account: current_account
      )

      if creator.call
        @facebook_channel = creator.channel
        redirect_to(edit_channels_facebook_path(@facebook_channel), notice: t("dashboard.facebook_channels.created"))
      else
        redirect_to(new_channels_facebook_path, alert: t("dashboard.facebook_channels.create_failed"))
      end
    end


    def update
      current_account.with_shard do
        if @facebook_channel.update(facebook_channel_update_params)
          redirect_to(channels_settings_path(type: "facebook"), notice: t("dashboard.facebook_channels.updated"))
        else
          render(:edit, status: :unprocessable_entity)
        end
      end
    end

    def destroy
      current_account.with_shard do
        @facebook_channel.destroy
      end
      current_account.decrement_usage!(:channels)

      respond_to do |format|
        format.html { redirect_to(channels_settings_path(type: "facebook"), notice: t("dashboard.facebook_channels.destroyed")) }
        format.turbo_stream { render(turbo_stream: turbo_stream.remove(@facebook_channel)) }
      end
    end

    # POST /facebook_channels/:id/reconnect
    # Triggers the re-authorization flow when a token has been invalidated.
    def reconnect
      current_account.with_shard do
        @facebook_channel.refresh_page_token!
      end
      redirect_to(channels_settings_path(type: "facebook"), notice: t("dashboard.facebook_channels.reconnected"))
    rescue StandardError => e
      Rails.logger.error("Facebook reconnect failed for #{@facebook_channel.page_identifier}: #{e.message}")
      redirect_to(channels_settings_path(type: "facebook"), alert: t("dashboard.facebook_channels.reconnect_failed"))
    end

    private

    def set_facebook_channel
      current_account.with_shard do
        @facebook_channel = Channel::FacebookPage.find_by!(id: params[:id], account: current_account)
      end
    end

    def authorize_facebook_channel
      authorize(:facebook_channel)
    end

    def facebook_channel_create_params
      params.expect(
        facebook_channel: [ :name, :access_token, :user_access_token,
        :page_identifier, :avatar_url ]
      ).to_h
    end

    def facebook_channel_update_params
      params.expect(
        facebook_channel: [ :name,
        primary_inbox_attributes: [
          :id, :reopen_window_seconds, :csat_survey_enabled, :csat_survey_id,
          :business_hour_group_id,
          sla_policy_ids: []
        ] ]
      )
    end
    end
  end
end
