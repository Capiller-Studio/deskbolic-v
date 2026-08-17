# frozen_string_literal: true

module Dashboard
  class IntegrationsController < DashboardController
      before_action :set_integration, only: [ :edit, :update, :destroy ]

      def index
        authorize(:integration, :index?)
        @integrations = current_account.integrations

        @slack = @integrations.find { |i| i.slack? }
        @webhooks = @integrations.select { |i| i.webhook? }
        @google_translate = @integrations.find { |i| i.google_translate? }

        # Slack OAuth configuration
        @slack_client_id = Rails.application.credentials.dig(Rails.env.to_sym, :slack, :client_id)
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
        @integration.active = true

        # Automatically generate webhook secret if none provided
        if @integration.webhook? && @integration.settings["webhook_secret"].blank?
          @integration.settings["webhook_secret"] = SecureRandom.hex(24)
        end

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

      # GET /settings/integrations/slack/callback
      def slack_callback
        authorize(:integration, :slack_callback?)
        code = params[:code]

        if code.blank? || params[:error].present?
          redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.auth_failed"))
          return
        end

        client_id = Rails.application.credentials.dig(Rails.env.to_sym, :slack, :client_id)
        client_secret = Rails.application.credentials.dig(Rails.env.to_sym, :slack, :client_secret)

        if client_id.blank? || client_secret.blank?
          redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.not_configured"))
          return
        end

        uri = URI("https://slack.com/api/oauth.v2.access")
        response = Net::HTTP.post_form(uri, {
          client_id: client_id,
          client_secret: client_secret,
          code: code,
          redirect_uri: slack_callback_integrations_url
        })

        result = JSON.parse(response.body)

        if result["ok"]
          webhook_url = result.dig("incoming_webhook", "url")

          integration = current_account.integrations.find_or_initialize_by(provider: :slack)
          integration.settings = { "webhook_url" => webhook_url }
          integration.active = true

          if integration.save
            redirect_to(integrations_path, notice: t("dashboard.settings.integrations.slack.connected"))
          else
            redirect_to(integrations_path, alert: integration.errors.full_messages.to_sentence)
          end
        else
          error_msg = result["error"] || "Unknown error"
          redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.exchange_failed", error: error_msg))
        end
      rescue StandardError => e
        Rails.logger.error("Slack OAuth Error: #{e.message}")
        redirect_to(integrations_path, alert: t("dashboard.settings.integrations.slack.unexpected_error"))
      end

      private

      def set_integration
        @integration = current_account.integrations.find(params[:id])
      end

      def integration_params
        permitted = params.expect(integration: [ :provider, :active ])

        if params[:integration][:settings].present?
          settings_params = params[:integration].require(:settings).permit(
            :webhook_url,
            :webhook_secret,
            subscribed_events: []
          )

          if settings_params[:subscribed_events].is_a?(Array)
            settings_params[:subscribed_events] = settings_params[:subscribed_events].compact_blank
          end

          permitted[:settings] = settings_params.to_h
        end

        permitted
      end
  end
end
