# frozen_string_literal: true

require "jwt"

module Dashboard
  class IntegrationsController < DashboardController
    skip_before_action :authenticate_user!, only: [ :slack_callback ]
    skip_before_action :ensure_subdomain_for_account, only: [ :slack_callback ]
    skip_before_action :enforce_active_subscription, only: [ :slack_callback ]
    before_action :set_integration, only: [ :edit, :update, :destroy ]

    def index
      authorize(:integration, :index?)
      @integrations = current_account.integrations

      @slack = @integrations.find { |i| i.slack? }
      @webhooks = @integrations.select { |i| i.webhook? }
      @google_translate = @integrations.find { |i| i.google_translate? }

      # Slack OAuth configuration
      @slack_client_id = slack_client_id
    end

    def new
      authorize(:integration, :create?)
      @provider = params[:provider]

      unless Integration.providers.key?(@provider)
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.invalid_provider"))
        return
      end

      @integration = current_account.integrations.new(provider: @provider)
    end

    def edit
      authorize(:integration, :update?)
      @provider = @integration.provider
    end

    def create
      authorize(:integration, :create?)
      @integration = current_account.integrations.new(integration_params)
      @integration.status = :active

      # Automatically generate webhook secret if none provided
      if @integration.webhook? && @integration.webhook_secret.blank?
        @integration.credentials["webhook_secret"] = SecureRandom.hex(24)
      end
      @integration.metadata["created_by_user_id"] = current_user&.id

      if @integration.save
        redirect_to(integrations_path, notice: t("dashboard.settings.integrations.created"))
      else
        @provider = @integration.provider
        render(:new, status: :unprocessable_entity)
      end
    end

    def update
      authorize(:integration, :update?)
      if @integration.update(integration_params)
        redirect_to(integrations_path, notice: t("dashboard.settings.integrations.updated"))
      else
        @provider = @integration.provider
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(:integration, :destroy?)
      @integration.destroy
      redirect_to(integrations_path, notice: t("dashboard.settings.integrations.destroyed"))
    end

    # GET /integrations/slack/oauth_authorize
    def oauth_authorize_slack
      authorize(:integration, :oauth_authorize_slack?)
      client_id = slack_client_id

      if client_id.blank?
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.not_configured"))
        return
      end

      callback_uri = slack_callback_url
      state = generate_state_token(current_account.id, callback_uri)

      params = {
        client_id: client_id,
        scope: "incoming-webhook,chat:write,chat:write.public",
        redirect_uri: callback_uri,
        state: state
      }

      redirect_to("https://slack.com/oauth/v2/authorize?#{params.to_query}", allow_other_host: true)
    end

    # GET /integrations/slack/callback
    def slack_callback
      if params[:error].present?
        redirect_target = current_account ? integrations_path : root_path
        redirect_to(redirect_target, alert: t("dashboard.settings.integrations.slack.auth_failed"))
        return
      end

      clean_code = params[:code].to_s.strip
      state_payload = verify_state_token(params[:state])
      account_id = state_payload.is_a?(Hash) ? state_payload["sub"] : state_payload

      if account_id.blank?
        redirect_target = current_account ? integrations_path : root_path
        redirect_to(redirect_target, alert: t("dashboard.settings.integrations.slack.unexpected_error"))
        return
      end

      target_account = Account.find_by(id: account_id)
      if target_account.blank?
        redirect_to(root_path, alert: t("dashboard.settings.integrations.slack.unexpected_error"))
        return
      end

      # If accessed on apex domain (or wrong subdomain), redirect to the account's subdomain callback
      if request.subdomain.blank? || request.subdomain == "www" || current_account&.id != target_account.id
        redirect_to(slack_callback_integrations_url(
          subdomain: target_account.identifier,
          code: clean_code,
          state: params[:state]
        ), allow_other_host: true)
        return
      end

      authenticate_user!
      authorize(:integration, :slack_callback?)

      client_id = slack_client_id
      client_secret = slack_client_secret

      if client_id.blank? || client_secret.blank?
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.not_configured"))
        return
      end

      token_redirect_uri = (state_payload.is_a?(Hash) && state_payload["redirect_uri"].presence) || slack_callback_url

      uri = URI("https://slack.com/api/oauth.v2.access")
      response = Net::HTTP.post_form(uri, {
        client_id: client_id,
        client_secret: client_secret,
        code: clean_code,
        redirect_uri: token_redirect_uri
      })

      result = JSON.parse(response.body)

      if result["ok"]
        webhook_info = result["incoming_webhook"] || {}
        team_info = result["team"] || {}

        integration = current_account.integrations.find_or_initialize_by(provider: :slack)
        integration.settings = {
          "webhook_url" => webhook_info["url"],
          "channel" => webhook_info["channel"],
          "channel_id" => webhook_info["channel_id"]
        }
        integration.credentials = {
          "access_token" => result["access_token"],
          "bot_user_id" => result["bot_user_id"],
          "scope" => result["scope"]
        }
        integration.metadata = {
          "team_name" => team_info["name"],
          "team_id" => team_info["id"],
          "configuration_url" => webhook_info["configuration_url"],
          "connected_by_user_id" => current_user&.id,
          "connected_at" => Time.current.iso8601
        }
        integration.status = :active

        if integration.save
          channel_name = webhook_info["channel"].presence || "Slack"
          redirect_to(integrations_path, notice: t("dashboard.settings.integrations.slack.connected", channel: channel_name))
        else
          redirect_to(integrations_path, alert: integration.errors.full_messages.to_sentence)
        end
      else
        error_msg = result["error"] || "Unknown error"
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.exchange_failed", error: error_msg))
      end
    rescue StandardError => e
      Rails.logger.error("Slack OAuth Error: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      fallback_target = current_account ? integrations_path : root_path
      redirect_to(fallback_target, alert: t("dashboard.settings.integrations.slack.unexpected_error"))
    end

    # POST /integrations/slack/test
    def test_slack
      authorize(:integration, :test_slack?)
      integration = current_account.integrations.find_by(provider: :slack, status: :active)

      if integration&.webhook_url.blank?
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.not_configured"))
        return
      end

      test_payload = {
        "event" => "message.created",
        "message_type" => "incoming",
        "content" => "This is a test notification from Deskbolic! Your Slack integration is connected and working properly. 🎉",
        "source" => "Deskbolic Test",
        "account" => {
          "id" => current_account.id,
          "identifier" => current_account.identifier,
          "name" => current_account.name,
          "locale" => current_account.locale
        },
        "conversation" => {
          "id" => "test-sample",
          "channel_type" => "web_widget"
        },
        "sender" => {
          "name" => current_user.name || "Admin",
          "email" => current_user.email
        }
      }

      delivery = Webhook::Delivery.create!(
        account: current_account,
        resource: integration,
        event_name: "message.created",
        endpoint_url: integration.webhook_url,
        request_payload: test_payload,
        status: :pending
      )

      Integrations::Slack::NotifierWorker.perform_async(current_account.id, delivery.id, 1)

      channel_name = integration.settings["channel"].presence || "Slack"
      redirect_to(integrations_path, notice: t("dashboard.settings.integrations.slack.test_sent", channel: channel_name))
    end

    private

    def set_integration
      @integration = current_account.integrations.find(params[:id])
    end

    def generate_state_token(account_id, redirect_uri = nil)
      secret = slack_signing_secret || Rails.application.secret_key_base
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
      secret = slack_signing_secret || Rails.application.secret_key_base
      decoded = ::JWT.decode(token, secret, true, { algorithm: "HS256" })
      decoded.first
    rescue ::JWT::DecodeError, ::JWT::ExpiredSignature => e
      Rails.logger.error("Slack state token verification failed: #{e.message}")
      nil
    end

    def slack_client_id
      Rails.application.credentials.dig(:integrations, :slack, :client_id) || ENV["SLACK_CLIENT_ID"]
    end

    def slack_client_secret
      Rails.application.credentials.dig(:integrations, :slack, :client_secret) || ENV["SLACK_CLIENT_SECRET"]
    end

    def slack_signing_secret
      Rails.application.credentials.dig(:integrations, :slack, :signing_secret) || ENV["SLACK_SIGNING_SECRET"]
    end

    def slack_callback_url
      base = ENV["DESKBOLIC_URL"].presence || "#{request.protocol}#{request.host_with_port}"
      URI.join(base, "/integrations/slack/callback").to_s
    end

    def integration_params
      permitted = params.expect(integration: [ :provider, :status, :name ])

      if params[:integration][:settings].present?
        settings_params = params[:integration].require(:settings).permit(
          :webhook_url,
          :channel,
          :channel_id,
          subscribed_events: [],
          subscribed_inboxes: []
        )

        if settings_params[:subscribed_events].is_a?(Array)
          settings_params[:subscribed_events] = settings_params[:subscribed_events].compact_blank
        end

        if settings_params[:subscribed_inboxes].is_a?(Array)
          settings_params[:subscribed_inboxes] = settings_params[:subscribed_inboxes].compact_blank
        end

        permitted[:settings] = settings_params.to_h
      end

      permitted
    end
  end
end
