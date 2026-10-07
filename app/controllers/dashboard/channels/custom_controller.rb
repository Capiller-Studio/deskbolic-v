# frozen_string_literal: true

module Dashboard
  module Channels
    class CustomController < DashboardController
      before_action :set_custom_channel, only: %i[show edit update destroy test_outgoing_webhook test_incoming_webhook]
      before_action :authorize_custom_channel

      helper Dashboard::Channels::CustomHelper

      def index
        @custom_channels = current_account.with_shard do
          Channel::Custom.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def show; end

      def new
        @custom_channel = Channel::Custom.new
      end

      def edit; end
      def create
        unless current_account.within_limit?(:channels)
          redirect_to(channels_custom_index_path, alert: t("dashboard.custom_channels.limit_reached", default: "Channel limit reached"))
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "custom",
          channel_params: custom_channel_create_params,
          current_account: current_account,
          current_user: current_user
        )

        if creator.call
          @custom_channel = creator.channel
          redirect_to(edit_channels_custom_path(@custom_channel), notice: t("dashboard.custom_channels.created", default: "Custom Channel created"))
        else
          redirect_to(new_channels_custom_path, alert: t("dashboard.custom_channels.create_failed", default: "Failed to create Custom Channel"))
        end
      end


      def update
        current_account.with_shard do
          # Map key-value builder arrays back into a hash for JSONB persistence
          processed_params = custom_channel_update_params.to_h

          if params[:channel_custom][:headers].is_a?(ActionController::Parameters)
            processed_params[:headers] = params[:channel_custom][:headers].values.reject { |h| h[:key].blank? }.each_with_object({}) { |h, hash| hash[h[:key]] = h[:value] }
          end

          if params[:channel_custom][:response_mapping].is_a?(ActionController::Parameters)
            processed_params[:response_mapping] = params[:channel_custom][:response_mapping].values.reject { |m| m[:key].blank? }.each_with_object({}) { |m, hash| hash[m[:key]] = m[:value] }
          end

          if @custom_channel.update(processed_params)
            redirect_to(channels_custom_index_path, notice: t("dashboard.custom_channels.updated", default: "Custom Channel updated"))
          else
            render(:edit, status: :unprocessable_entity)
          end
        end
      end

      def destroy
        current_account.with_shard do
          @custom_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to(channels_custom_index_path, notice: t("dashboard.custom_channels.destroyed", default: "Custom Channel deleted"), status: :see_other) }
          format.turbo_stream { redirect_to(channels_custom_index_path, notice: t("dashboard.custom_channels.destroyed", default: "Custom Channel deleted"), status: :see_other) }
        end
      end

      # --- Webhook Testing Sandbox ---

      def test_outgoing_webhook
        payload = {
          event: "message.created",
          data: {
            message: "This is a test message from Deskbolic.",
            customer_id: "cus_123",
            conversation_id: "con_123"
          }
        }

        validation = Security::UrlValidator.validate(@custom_channel.webhook_url)
        unless validation[:valid]
          return render(json: { error: I18n.t("dashboard.channels.custom.insecure_webhook_url", error: validation[:error], default: "Insecure or invalid webhook URL: %{error}") }, status: :unprocessable_entity)
        end

        uri = URI.parse(@custom_channel.webhook_url)

        # In development, gracefully handle localhost to avoid Puma thread lock
        if Rails.env.development? && %w[localhost 127.0.0.1].include?(uri.host)
          env = Rack::MockRequest.env_for(
            uri.request_uri || "/",
            method: "POST",
            input: payload.to_json,
            "CONTENT_TYPE" => "application/json",
            "HTTP_HOST" => "#{uri.host}:#{uri.port}"
          )
          @custom_channel.headers.each { |k, v| env["HTTP_#{k.upcase.tr('-', '_')}"] = v }

          # Include HMAC Signature with Timestamp
          timestamp = Time.now.to_i
          signature = OpenSSL::HMAC.hexdigest("SHA256", @custom_channel.webhook_secret, "#{timestamp}-#{payload.to_json}")
          env["HTTP_DESKBOLIC_SIGNATURE"] = "t=#{timestamp},v1=#{signature}"

          # Bypass the entire middleware stack (Executor, MiniProfiler) to prevent deadlocks and thread-local corruption
          # by calling the router directly in the same thread.
          status, _headers, body_proxy = Rails.application.routes.call(env)

          response_body = ""
          body_proxy.each { |part| response_body += part }
          body_proxy.close if body_proxy.respond_to?(:close)

          parsed_body = JSON.parse(response_body) rescue response_body
          render(json: parsed_body, status: status)
          return
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 5
        http.read_timeout = 10

        request = Net::HTTP::Post.new(uri.request_uri || "/")
        request.content_type = "application/json"
        request.body = payload.to_json

        @custom_channel.headers.each do |k, v|
          request[k] = v
        end

        # Include HMAC Signature with Timestamp
        timestamp = Time.now.to_i
        signature = OpenSSL::HMAC.hexdigest("SHA256", @custom_channel.webhook_secret, "#{timestamp}-#{request.body}")
        request["Deskbolic-Signature"] = "t=#{timestamp},v1=#{signature}"

        begin
          response = http.request(request)
          parsed_body = JSON.parse(response.body) rescue response.body
          render(json: parsed_body, status: response.code)
        rescue StandardError => e
          render(json: { error: e.message }, status: :unprocessable_entity)
        end
      end

      def test_incoming_webhook
        # In the future, this will simulate what happens when a third-party posts to our webhook.
        # For now, we just validate the user's JSON payload against their mapping.

        begin
          payload = JSON.parse(params[:payload])
          mapped_result = {}

          @custom_channel.response_mapping.each do |deskbolic_key, json_path|
            # Simple JSON path extraction (e.g., 'customer.id' -> payload['customer']['id'])
            value = json_path.split(".").reduce(payload) { |hash, key| hash.dig(key) rescue nil }
            mapped_result[deskbolic_key] = value
          end

          render(json: { mapped_result: mapped_result })
        rescue JSON::ParserError
          render(json: { error: "Invalid JSON payload" }, status: :unprocessable_entity)
        end
      end

      private

      def set_custom_channel
        current_account.with_shard do
          @custom_channel = Channel::Custom.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_custom_channel
        authorize(:custom_channel)
      end

      def custom_channel_create_params
        params.expect(channel_custom: [ :name, :description, :webhook_url ]).to_h
      end

      def custom_channel_update_params
        params.expect(
          channel_custom: [ :name, :description, :webhook_url,
          primary_inbox_attributes: [
            :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id,
            :conversation_reply_template_id, :business_hour_group_id, :ai_classification, :ai_auto_labelling,
            sla_policy_ids: [], user_ids: [], team_ids: []
          ] ]
        )
      end
    end
  end
end
