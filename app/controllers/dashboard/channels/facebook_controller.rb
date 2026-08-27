# frozen_string_literal: true

require "jwt"

module Dashboard
  module Channels
    class FacebookController < DashboardController
      skip_before_action :authenticate_user!, only: [ :callback ]
      skip_before_action :ensure_subdomain_for_account, only: [ :callback ]
      skip_before_action :enforce_active_subscription, only: [ :callback ]
      before_action :set_facebook_channel, only: %i[edit update destroy reconnect]
      before_action :authorize_facebook_channel, except: [ :callback ]

      def index
        @facebook_channels = current_account.with_shard do
          Channel::FacebookPage.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def new
        @facebook_channel = Channel::FacebookPage.new
        @facebook_app_id = facebook_app_id
      end

      # GET /channels/facebook/oauth_authorize
      # Generates the Facebook OAuth dialog URL and redirects the user
      def oauth_authorize
        callback_uri = facebook_callback_url
        state = generate_state_token(current_account.id, callback_uri)

        scopes = %w[
          pages_show_list
          pages_read_engagement
          pages_manage_metadata
          pages_messaging
        ].join(",")

        query_params = {
          client_id: facebook_app_id,
          redirect_uri: callback_uri,
          scope: scopes,
          response_type: "code",
          state: state
        }

        redirect_url = "https://www.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/dialog/oauth?#{query_params.to_query}"
        redirect_to(redirect_url, allow_other_host: true)
      end

      # GET/POST /channels/facebook/callback
      # Receives the authorization code (from server-side redirect) or token (legacy)
      # and exchanges it for a list of pages with permanent page access tokens.
      def callback
        if params[:error].present?
          redirect_target = current_account ? new_channels_facebook_path : root_path
          redirect_to(redirect_target, alert: params[:error_description] || t("dashboard.facebook_channels.callback_error"))
          return
        end

        # Handle legacy client-side token POST
        if request.post? && params[:access_token].present?
          authenticate_user!
          authorize(:facebook_channel)

          result = ::Channels::FacebookPages::TokenExchangeService.call(
            short_lived_token: params[:access_token],
            account: current_account
          )

          process_callback_result(result)
          return
        end

        # Server-side OAuth redirect flow (GET)
        clean_code = params[:code].to_s.split("#").first.gsub(/%23.*/, "").strip
        if clean_code.blank?
          redirect_target = current_account ? new_channels_facebook_path : root_path
          redirect_to(redirect_target, alert: t("dashboard.facebook_channels.callback_error"))
          return
        end

        state_payload = verify_state_token(params[:state])
        account_id = state_payload.is_a?(Hash) ? state_payload["sub"] : state_payload
        account_id ||= current_account&.id

        if account_id.blank?
          redirect_target = current_account ? new_channels_facebook_path : root_path
          redirect_to(redirect_target, alert: t("dashboard.facebook_channels.invalid_state", default: "Invalid session. Please try again."))
          return
        end

        target_account = Account.find_by(id: account_id)
        if target_account.blank?
          redirect_to(root_path, alert: t("dashboard.facebook_channels.invalid_state", default: "Account not found."))
          return
        end

        # If accessed on apex domain (or wrong subdomain), redirect to the account's subdomain callback
        if request.subdomain.blank? || request.subdomain == "www" || current_account&.id != target_account.id
          redirect_to(callback_channels_facebook_index_url(
            subdomain: target_account.identifier,
            code: clean_code,
            state: params[:state]
          ), allow_other_host: true)
          return
        end

        # Ensure user is authenticated and authorized on the subdomain
        authenticate_user!
        authorize(:facebook_channel)

        token_redirect_uri = (state_payload.is_a?(Hash) && state_payload["redirect_uri"].presence) || facebook_callback_url

        result = ::Channels::FacebookPages::TokenExchangeService.call(
          code: clean_code,
          redirect_uri: token_redirect_uri,
          account: current_account
        )

        process_callback_result(result)
      rescue StandardError => e
        Rails.logger.error("Facebook token exchange failed: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
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
            redirect_to(channels_facebook_index_path, notice: t("dashboard.facebook_channels.updated"))
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
          format.html { redirect_to(channels_facebook_index_path, notice: t("dashboard.facebook_channels.destroyed")) }
          format.turbo_stream { render(turbo_stream: turbo_stream.remove(@facebook_channel)) }
        end
      end

      # POST /channels/facebook/:id/reconnect
      def reconnect
        current_account.with_shard do
          @facebook_channel.refresh_page_token!
        end
        redirect_to(channels_facebook_index_path, notice: t("dashboard.facebook_channels.reconnected"))
      rescue StandardError => e
        Rails.logger.error("Facebook reconnect failed for #{@facebook_channel.page_identifier}: #{e.message}")
        redirect_to(channels_facebook_index_path, alert: t("dashboard.facebook_channels.reconnect_failed"))
      end

      private

      def process_callback_result(result)
        @pages = result[:pages]
        @user_access_token = result[:user_access_token]

        # Filter out pages already connected to this account
        connected_page_ids = current_account.with_shard do
          Channel::FacebookPage.where(account: current_account).pluck(:page_identifier)
        end
        @pages.each { |p| p[:already_connected] = connected_page_ids.include?(p[:id]) }

        @facebook_channel = Channel::FacebookPage.new
        @facebook_app_id = facebook_app_id

        respond_to do |format|
          format.turbo_stream
          format.html { render(:new) }
        end
      end

      def set_facebook_channel
        current_account.with_shard do
          @facebook_channel = Channel::FacebookPage.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_facebook_channel
        authorize(:facebook_channel)
      end

      def facebook_app_id
        Rails.application.credentials.dig(:channels, :facebook, :app_id)&.to_s&.strip
      end

      def facebook_app_secret
        Rails.application.credentials.dig(:channels, :facebook, :app_secret)&.to_s&.strip
      end

      # JWT-based state parameter to prevent CSRF during OAuth redirect and preserve exact redirect_uri
      def generate_state_token(account_id, redirect_uri = nil)
        payload = {
          sub: account_id,
          iat: Time.current.to_i,
          exp: 15.minutes.from_now.to_i
        }
        payload[:redirect_uri] = redirect_uri if redirect_uri.present?
        ::JWT.encode(payload, facebook_app_secret, "HS256")
      end

      def verify_state_token(token)
        return nil if token.blank?
        decoded = ::JWT.decode(token, facebook_app_secret, true, { algorithm: "HS256" })
        decoded.first
      rescue ::JWT::DecodeError, ::JWT::ExpiredSignature => e
        Rails.logger.error("Facebook state token verification failed: #{e.message}")
        nil
      end

      def facebook_callback_url
        base = ENV["DESKBOLIC_URL"].presence || "#{request.protocol}#{request.host_with_port}"
        URI.join(base, "/channels/facebook/callback").to_s
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
