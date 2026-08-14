# frozen_string_literal: true
require "jwt"

module Dashboard
  module Channels
    class InstagramController < DashboardController
      before_action :set_instagram_channel, only: %i[edit update destroy]
      before_action :authorize_instagram_channel

      def index
        @instagram_channels = current_account.with_shard do
          Channel::Instagram.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def new
        @instagram_channel = Channel::Instagram.new
      end

      # GET /instagram_channels/oauth_authorize
      # Generates the Instagram OAuth URL and redirects the user to Instagram
      def oauth_authorize
        state = generate_state_token(current_account.id)

        oauth_service = ::Channels::Instagram::OauthService.new(account: current_account)
        redirect_url = oauth_service.authorization_url(
          redirect_uri: instagram_callback_url,
          state: state
        )

        redirect_to redirect_url, allow_other_host: true
      end

      # GET /instagram_channels/callback
      # Instagram redirects here after the user authorizes (or denies) the app
      def callback
        if params[:error].present?
          redirect_to new_channels_instagram_path, alert: params[:error_description] || t("dashboard.instagram_channels.callback_error")
          return
        end

        account_id = verify_state_token(params[:state])
        unless account_id == current_account.id
          redirect_to new_channels_instagram_path, alert: t("dashboard.instagram_channels.invalid_state")
          return
        end

        oauth_service = ::Channels::Instagram::OauthService.new(account: current_account)
        
        # Strip potential #_ fragment that Meta sometimes appends
        safe_code = params[:code].to_s.gsub(/#_\z/, "")
        
        result = oauth_service.exchange_code(
          code: safe_code,
          redirect_uri: instagram_callback_url
        )

        unless current_account.within_limit?(:channels)
          redirect_to channels_instagram_index_path, alert: t("dashboard.instagram_channels.limit_reached")
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "instagram",
          channel_params: {
            instagram_id: result[:user][:id],
            username: result[:user][:username],
            name: result[:user][:name],
            avatar_url: result[:user][:avatar_url],
            access_token: result[:access_token],
            expires_at: result[:expires_at]
          },
          current_account: current_account
        )

        if creator.call
          redirect_to edit_channels_instagram_path(creator.channel), notice: t("dashboard.instagram_channels.created")
        else
          redirect_to new_channels_instagram_path, alert: t("dashboard.instagram_channels.create_failed")
        end
      rescue StandardError => e
        Rails.logger.error("Instagram OAuth callback error: #{e.message}")
        redirect_to new_channels_instagram_path, alert: t("dashboard.instagram_channels.callback_error")
      end

      def edit; end

      def update
        current_account.with_shard do
          if @instagram_channel.update(instagram_channel_update_params)
            redirect_to channels_settings_path(type: "instagram"), notice: t("dashboard.instagram_channels.updated")
          else
            render :edit, status: :unprocessable_entity
          end
        end
      end

      def destroy
        current_account.with_shard do
          @instagram_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to channels_settings_path(type: "instagram"), notice: t("dashboard.instagram_channels.destroyed") }
          format.turbo_stream { render turbo_stream: turbo_stream.remove(@instagram_channel) }
        end
      end

      private

      def set_instagram_channel
        current_account.with_shard do
          @instagram_channel = Channel::Instagram.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_instagram_channel
        authorize :instagram_channel
      end

      def instagram_channel_update_params
        params.require(:instagram_channel).permit(
          :name,
          primary_inbox_attributes: [
            :id, :reopen_window_seconds, :csat_survey_enabled, :csat_survey_id, :business_hour_group_id,
            sla_policy_ids: []
          ]
        )
      end

      # JWT-based state parameter to prevent CSRF during OAuth redirect
      def generate_state_token(account_id)
        secret = Rails.application.credentials.dig(:channels, :instagram, :app_secret)
        ::JWT.encode({ sub: account_id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, "HS256")
      end

      def verify_state_token(token)
        secret = Rails.application.credentials.dig(:channels, :instagram, :app_secret)
        decoded = ::JWT.decode(token, secret, true, { algorithm: "HS256" })
        decoded.first["sub"]
      rescue ::JWT::DecodeError, ::JWT::ExpiredSignature => e
        Rails.logger.error("Instagram state token verification failed: #{e.message}")
        nil
      end

      def instagram_callback_url
        # Enforce a consistent URL string using DESKBOLIC_URL to prevent OAuth 400 errors
        # caused by host mismatches.
        URI.join(
          ENV.fetch("DESKBOLIC_URL", "https://deskbolic.app"),
          callback_channels_instagram_index_path(locale: nil)
        ).to_s
      end
    end
  end
end
