# frozen_string_literal: true

require "jwt"

module Dashboard
  module Channels
    class WhatsappController < DashboardController
      skip_before_action :authenticate_user!, only: [ :callback ]
      skip_before_action :ensure_subdomain_for_account, only: [ :callback ]
      skip_before_action :enforce_active_subscription, only: [ :callback ]
      before_action :set_whatsapp_channel, only: %i[show edit update destroy reconnect]
      before_action :authorize_whatsapp_channel, except: [ :callback ]

      def index
        @whatsapp_channels = current_account.with_shard do
          Channel::Whatsapp.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def show; end

      def new
        @whatsapp_channel = Channel::Whatsapp.new
        @whatsapp_app_id = whatsapp_app_id
        @whatsapp_config_id = whatsapp_config_id
      end

      # GET /channels/whatsapp/oauth_authorize
      # Generates the Meta WhatsApp Embedded Signup OAuth URL and redirects the user
      def oauth_authorize
        callback_uri = whatsapp_callback_url
        state = generate_state_token(current_account.id, callback_uri)

        query_params = {
          client_id: whatsapp_app_id,
          redirect_uri: callback_uri,
          response_type: "code",
          state: state
        }

        if whatsapp_config_id.present?
          query_params[:config_id] = whatsapp_config_id
        else
          query_params[:scope] = "whatsapp_business_management,whatsapp_business_messaging"
        end

        redirect_url = "https://www.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/dialog/oauth?#{query_params.to_query}"
        redirect_to(redirect_url, allow_other_host: true)
      end

      # GET/POST /channels/whatsapp/callback
      # Meta redirects here after the user completes the Embedded Signup flow
      def callback
        if params[:error].present?
          redirect_target = current_account ? new_channels_whatsapp_path : root_path
          redirect_to(redirect_target, alert: params[:error_description] || t("dashboard.whatsapp_channels.callback_error"))
          return
        end

        # Clean code immediately from any hash fragment or URL encoding artifacts (#_ or %23_)
        clean_code = params[:code].to_s.split("#").first.gsub(/%23.*/, "").strip

        if clean_code.blank?
          redirect_target = current_account ? new_channels_whatsapp_path : root_path
          redirect_to(redirect_target, alert: t("dashboard.whatsapp_channels.callback_error"))
          return
        end

        state_payload = verify_state_token(params[:state])
        account_id = state_payload.is_a?(Hash) ? state_payload["sub"] : state_payload

        # For legacy POST callback or cases without state token
        account_id ||= current_account&.id

        if account_id.blank?
          redirect_target = current_account ? new_channels_whatsapp_path : root_path
          redirect_to(redirect_target, alert: t("dashboard.whatsapp_channels.invalid_state", default: "Invalid or expired session. Please try again."))
          return
        end

        target_account = Account.find_by(id: account_id)
        if target_account.blank?
          redirect_to(root_path, alert: t("dashboard.whatsapp_channels.invalid_state", default: "Account not found."))
          return
        end

        # If accessed on apex domain (or wrong subdomain), redirect to the account's subdomain callback
        if request.subdomain.blank? || request.subdomain == "www" || current_account&.id != target_account.id
          redirect_to(callback_channels_whatsapp_index_url(
            subdomain: target_account.identifier,
            code: clean_code,
            state: params[:state],
            waba_id: params[:waba_id],
            phone_number_id: params[:phone_number_id]
          ), allow_other_host: true)
          return
        end

        # Ensure user is authenticated and authorized on the subdomain
        authenticate_user!
        authorize(:whatsapp_channel)

        token_redirect_uri = (state_payload.is_a?(Hash) && state_payload["redirect_uri"].presence) || whatsapp_callback_url

        result = ::Channels::Whatsapp::SignupService.call(
          code: clean_code,
          redirect_uri: token_redirect_uri,
          waba_id: params[:waba_id],
          phone_number_id: params[:phone_number_id],
          account: current_account
        )

        unless current_account.within_limit?(:channels)
          redirect_to(channels_whatsapp_index_path, alert: t("dashboard.whatsapp_channels.limit_reached"))
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "whatsapp",
          channel_params: {
            name: result[:name].presence || result[:display_phone_number],
            api_key: result[:access_token],
            full_phone_number: result[:display_phone_number],
            phone_number_id: result[:phone_number_id],
            business_account_id: result[:waba_id],
            provider_embedded_signup: true
          },
          current_account: current_account,
          current_user: current_user
        )

        if creator.call
          @whatsapp_channel = creator.channel
          ::Channels::Whatsapp::SyncTemplatesWorker.perform_async(current_account.id, @whatsapp_channel.id)
          redirect_to(edit_channels_whatsapp_path(@whatsapp_channel), notice: t("dashboard.whatsapp_channels.created"), status: :see_other)
        else
          redirect_to(new_channels_whatsapp_path, alert: t("dashboard.whatsapp_channels.create_failed"), status: :see_other)
        end
      rescue StandardError => e
        Rails.logger.error("WhatsApp Embedded Signup failed: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
        fallback_target = current_account ? new_channels_whatsapp_path : root_path
        redirect_to(fallback_target, alert: t("dashboard.whatsapp_channels.callback_error"))
      end

      def edit; end

      # POST /whatsapp
      # Handles manual setup form submission
      def create
        unless current_account.within_limit?(:channels)
          redirect_to(channels_whatsapp_index_path, alert: t("dashboard.whatsapp_channels.limit_reached"))
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "whatsapp",
          channel_params: whatsapp_channel_create_params.merge(provider_embedded_signup: false),
          current_account: current_account,
          current_user: current_user
        )

        if creator.call
          @whatsapp_channel = creator.channel
          ::Channels::Whatsapp::SyncTemplatesWorker.perform_async(current_account.id, @whatsapp_channel.id)
          redirect_to(edit_channels_whatsapp_path(@whatsapp_channel), notice: t("dashboard.whatsapp_channels.created"), status: :see_other)
        else
          redirect_to(new_channels_whatsapp_path, alert: t("dashboard.whatsapp_channels.create_failed"), status: :see_other)
        end
      end

      def update
        current_account.with_shard do
          if @whatsapp_channel.update(whatsapp_channel_update_params)
            redirect_to(channels_whatsapp_index_path, notice: t("dashboard.whatsapp_channels.updated"), status: :see_other)
          else
            render(:edit, status: :unprocessable_entity)
          end
        end
      end

      def destroy
        current_account.with_shard do
          @whatsapp_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to(channels_whatsapp_index_path, notice: t("dashboard.whatsapp_channels.destroyed"), status: :see_other) }
          format.turbo_stream { redirect_to(channels_whatsapp_index_path, notice: t("dashboard.whatsapp_channels.destroyed"), status: :see_other) }
        end
      end

      # POST /whatsapp/:id/sync_templates
      def sync_templates
        current_account.with_shard do
          templates = @whatsapp_channel.sync_templates
          if templates.present?
            redirect_to(edit_channels_whatsapp_path(@whatsapp_channel),
                        notice: t("dashboard.whatsapp_channels.templates_synced", count: templates.size, default: "Successfully synced #{templates.size} approved template(s) from Meta."))
          else
            redirect_to(edit_channels_whatsapp_path(@whatsapp_channel),
                        alert: t("dashboard.whatsapp_channels.templates_sync_empty", default: "No approved templates found in your WhatsApp Business Account. Please check Meta WhatsApp Manager."))
          end
        end
      end

      # POST /whatsapp/:id/reconnect
      def reconnect
        current_account.with_shard do
          @whatsapp_channel.reauthorized!
          ::Channels::Whatsapp::SyncTemplatesWorker.perform_async(current_account.id, @whatsapp_channel.id)
        end

        redirect_back(fallback_location: edit_channels_whatsapp_path(@whatsapp_channel),
                      notice: t("dashboard.whatsapp_channels.reconnected", default: "Channel re-activated successfully. If your access token is truly expired, please update it."))
      end

      private

      def set_whatsapp_channel
        current_account.with_shard do
          @whatsapp_channel = Channel::Whatsapp.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_whatsapp_channel
        authorize(:whatsapp_channel)
      end

      def whatsapp_app_id
        (Rails.application.credentials.dig(:channels, :whatsapp, :app_id).presence ||
         Rails.application.credentials.dig(:channels, :facebook, :app_id))&.to_s&.strip
      end

      def whatsapp_config_id
        Rails.application.credentials.dig(:channels, :whatsapp, :configuration_id)&.to_s&.strip
      end

      def whatsapp_secret
        (Rails.application.credentials.dig(:channels, :whatsapp, :app_secret).presence ||
         Rails.application.credentials.dig(:channels, :facebook, :app_secret))&.to_s&.strip
      end

      # JWT-based state parameter to prevent CSRF during OAuth redirect and preserve exact redirect_uri
      def generate_state_token(account_id, redirect_uri = nil)
        payload = {
          sub: account_id,
          iat: Time.current.to_i,
          exp: 15.minutes.from_now.to_i
        }
        payload[:redirect_uri] = redirect_uri if redirect_uri.present?
        ::JWT.encode(payload, whatsapp_secret, "HS256")
      end

      def verify_state_token(token)
        return nil if token.blank?
        decoded = ::JWT.decode(token, whatsapp_secret, true, { algorithm: "HS256" })
        decoded.first
      rescue ::JWT::DecodeError, ::JWT::ExpiredSignature => e
        Rails.logger.error("WhatsApp state token verification failed: #{e.message}")
        nil
      end

      def whatsapp_callback_url
        base = ENV["DESKBOLIC_URL"].presence
        base ||= Rails.env.production? ? "https://deskbolic.app" : "#{request.protocol}#{request.host_with_port}"
        base = base.to_s.strip.chomp("/")
        "#{base}/channels/whatsapp/callback"
      end

      def whatsapp_channel_create_params
        params.expect(
          channel_whatsapp: [ :name, :phone_code, :phone_number, :full_phone_number,
          :phone_number_id, :business_account_id, :api_key ]
        ).to_h
      end

      def whatsapp_channel_update_params
        permitted = params.expect(
          channel_whatsapp: [
            :name, :api_key, :template_name, :template_language,
            primary_inbox_attributes: [
              :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id, :business_hour_group_id,
              :ai_classification, :ai_auto_labelling,
              sla_policy_ids: [], user_ids: [], team_ids: []
            ]
          ]
        )
        permitted.delete(:api_key) if permitted[:api_key].blank?
        permitted
      end
    end
  end
end
