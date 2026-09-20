# frozen_string_literal: true

require "jwt"

module Dashboard
  module Channels
    class InstagramController < DashboardController
      skip_before_action :authenticate_user!, only: [ :callback ]
      skip_before_action :ensure_subdomain_for_account, only: [ :callback ]
      skip_before_action :enforce_active_subscription, only: [ :callback ]
      before_action :set_instagram_channel, only: %i[show edit update destroy]
      before_action :authorize_instagram_channel, except: [ :callback ]

      def index
        @instagram_channels = current_account.with_shard do
          Channel::Instagram.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def show; end

      def new
        @instagram_channel = Channel::Instagram.new
      end

      # GET /instagram_channels/oauth_authorize
      # Generates the Instagram OAuth URL and redirects the user to Instagram
      def oauth_authorize
        callback_uri = instagram_callback_url
        Rails.logger.info("[Instagram OAuth] Initiating OAuth for account #{current_account.id} with callback_uri: #{callback_uri}")
        state = generate_state_token(current_account.id, callback_uri)

        oauth_service = ::Channels::Instagram::OauthService.new(account: current_account)
        redirect_url = oauth_service.authorization_url(
          redirect_uri: callback_uri,
          state: state
        )

        redirect_to(redirect_url, allow_other_host: true)
      end

      # GET /instagram_channels/callback
      # Instagram redirects here after the user authorizes (or denies) the app
      def callback
        if params[:error].present?
          Rails.logger.warn("[Instagram OAuth] Callback received error: #{params[:error]} - #{params[:error_description]}")
          redirect_target = current_account ? new_channels_instagram_path : root_path
          redirect_to(redirect_target, alert: params[:error_description] || t("dashboard.instagram_channels.callback_error"))
          return
        end

        # Clean code immediately from any hash fragment or URL encoding artifacts (#_ or %23_)
        clean_code = params[:code].to_s.split("#").first.gsub(/%23.*/, "").strip

        state_payload = verify_state_token(params[:state])
        account_id = state_payload.is_a?(Hash) ? state_payload["sub"] : state_payload
        if account_id.blank?
          Rails.logger.error("[Instagram OAuth] State token verification returned blank account_id")
          redirect_target = current_account ? new_channels_instagram_path : root_path
          redirect_to(redirect_target, alert: t("dashboard.instagram_channels.invalid_state"))
          return
        end

        target_account = Account.find_by(id: account_id)
        if target_account.blank?
          Rails.logger.error("[Instagram OAuth] Account #{account_id} from state token not found")
          redirect_to(root_path, alert: t("dashboard.instagram_channels.invalid_state"))
          return
        end

        # If accessed on apex domain (or wrong subdomain), redirect to the account's subdomain callback
        if request.subdomain.blank? || request.subdomain == "www" || current_account&.id != target_account.id
          target_url = callback_channels_instagram_index_url(
            subdomain: target_account.identifier,
            code: clean_code,
            state: params[:state]
          )
          Rails.logger.info("[Instagram OAuth] Apex callback received for account #{target_account.id} (#{target_account.identifier}). Redirecting to subdomain: #{target_url}")
          redirect_to(target_url, allow_other_host: true)
          return
        end

        # Ensure user is authenticated and authorized on the subdomain
        authenticate_user!
        authorize(:instagram_channel)

        oauth_service = ::Channels::Instagram::OauthService.new(account: current_account)

        # Use the exact redirect_uri stored in the verified JWT state payload to ensure 100% match with OAuth dialog
        token_redirect_uri = (state_payload.is_a?(Hash) && state_payload["redirect_uri"].presence) || instagram_callback_url
        token_redirect_uri = token_redirect_uri.to_s.strip.chomp("/")

        Rails.logger.info("[Instagram OAuth] Exchanging code on subdomain #{request.subdomain} for account #{current_account.id} with token_redirect_uri: #{token_redirect_uri}")

        result = oauth_service.exchange_code(
          code: clean_code,
          redirect_uri: token_redirect_uri
        )

        # Check if channel already exists for this Instagram account (re-authorization / reconnect)
        existing_channel = current_account.with_shard do
          Channel::Instagram.find_by(instagram_id: result[:user][:id], account: current_account)
        end

        if existing_channel.present?
          current_account.with_shard do
            existing_channel.update!(
              access_token: result[:access_token],
              expires_at: result[:expires_at],
              avatar_url: result[:user][:avatar_url],
              username: result[:user][:username],
              name: result[:user][:name].presence || result[:user][:username].presence || existing_channel.name,
              status: :active
            )
          end
          redirect_to(edit_channels_instagram_path(existing_channel), notice: t("dashboard.instagram_channels.updated", default: "Instagram channel updated successfully."))
          return
        end

        unless current_account.within_limit?(:channels)
          redirect_to(channels_instagram_index_path, alert: t("dashboard.instagram_channels.limit_reached"))
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "instagram",
          channel_params: {
            instagram_id: result[:user][:id],
            username: result[:user][:username],
            name: result[:user][:name].presence || result[:user][:username].presence || "Instagram",
            avatar_url: result[:user][:avatar_url],
            access_token: result[:access_token],
            expires_at: result[:expires_at]
          },
          current_account: current_account,
          current_user: current_user
        )

        if creator.call
          redirect_to(edit_channels_instagram_path(creator.channel), notice: t("dashboard.instagram_channels.created"))
        else
          redirect_to(new_channels_instagram_path, alert: t("dashboard.instagram_channels.create_failed"))
        end
      rescue StandardError => e
        Rails.logger.error("Instagram OAuth callback error: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
        fallback_target = current_account ? new_channels_instagram_path : root_path
        redirect_to(fallback_target, alert: t("dashboard.instagram_channels.callback_error"))
      end

      def edit; end

      def update
        current_account.with_shard do
          if @instagram_channel.update(instagram_channel_update_params)
            redirect_to(channels_instagram_index_path, notice: t("dashboard.instagram_channels.updated"))
          else
            render(:edit, status: :unprocessable_entity)
          end
        end
      end

      def destroy
        current_account.with_shard do
          @instagram_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to(channels_instagram_index_path, notice: t("dashboard.instagram_channels.destroyed")) }
          format.turbo_stream { render(turbo_stream: turbo_stream.remove(@instagram_channel)) }
        end
      end

      private

      def set_instagram_channel
        current_account.with_shard do
          @instagram_channel = Channel::Instagram.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_instagram_channel
        authorize(:instagram_channel)
      end

      def instagram_channel_update_params
        params.expect(
          instagram_channel: [
            :name,
            primary_inbox_attributes: [
              :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id, :business_hour_group_id,
              sla_policy_ids: [], user_ids: [], team_ids: []
            ]
          ]
        )
      end

      # JWT-based state parameter to prevent CSRF during OAuth redirect and preserve exact redirect_uri
      def generate_state_token(account_id, redirect_uri = nil)
        secret = Rails.application.credentials.dig(:channels, :instagram, :app_secret)
        payload = {
          sub: account_id,
          iat: Time.current.to_i,
          exp: 15.minutes.from_now.to_i
        }
        payload[:redirect_uri] = redirect_uri if redirect_uri.present?
        ::JWT.encode(payload, secret, "HS256")
      end

      def verify_state_token(token)
        return nil if token.blank?
        secret = Rails.application.credentials.dig(:channels, :instagram, :app_secret)
        decoded = ::JWT.decode(token, secret, true, { algorithm: "HS256" })
        decoded.first
      rescue ::JWT::DecodeError, ::JWT::ExpiredSignature => e
        Rails.logger.error("Instagram state token verification failed: #{e.message}")
        nil
      end

      def instagram_callback_url
        # In production with DESKBOLIC_URL, use configured apex URL (matches Meta Console: https://deskbolic.app/channels/instagram/callback).
        # In local/ngrok environments, dynamically use the current request host (matches ngrok in Meta Console).
        base = ENV["DESKBOLIC_URL"].presence
        base ||= Rails.env.production? ? "https://deskbolic.app" : "#{request.protocol}#{request.host_with_port}"
        base = base.to_s.strip.chomp("/")
        "#{base}/channels/instagram/callback"
      end
    end
  end
end
