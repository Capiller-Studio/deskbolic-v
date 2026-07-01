# frozen_string_literal: true

module Dashboard
  module Channels
    class WhatsappController < DashboardController
      before_action :set_whatsapp_channel, only: %i[edit update destroy reconnect]
      before_action :authorize_whatsapp_channel

      def index
        @whatsapp_channels = current_account.with_shard do
          Channel::Whatsapp.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def new
        @whatsapp_channel = Channel::Whatsapp.new
        @whatsapp_app_id = Rails.application.credentials.dig(:channels, :whatsapp, :app_id)
        @whatsapp_config_id = Rails.application.credentials.dig(:channels, :whatsapp, :configuration_id)
      end

      # POST /whatsapp/callback
      # Receives the authorization code from the Embedded Signup flow
      # and exchanges it for a permanent business token + WABA ID + Phone Number ID
      def callback
        result = ::Channels::Whatsapp::SignupService.call(
          code: params[:code],
          account: current_account
        )

        unless current_account.within_limit?(:channels)
          redirect_to channels_whatsapp_index_path, alert: t("dashboard.whatsapp_channels.limit_reached")
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "whatsapp",
          channel_params: {
            name: result[:display_phone_number] || result[:phone_number_id],
            api_key: result[:access_token],
            full_phone_number: result[:display_phone_number],
            phone_number_id: result[:phone_number_id],
            business_account_id: result[:waba_id],
            provider_embedded_signup: true
          },
          current_account: current_account
        )

        if creator.call
          @whatsapp_channel = creator.channel
          redirect_to edit_channels_whatsapp_path(@whatsapp_channel), notice: t("dashboard.whatsapp_channels.created"), status: :see_other
        else
          redirect_to new_channels_whatsapp_path, alert: t("dashboard.whatsapp_channels.create_failed"), status: :see_other
        end
      rescue StandardError => e
        Rails.logger.error("WhatsApp Embedded Signup failed: #{e.message}")
        redirect_to new_channels_whatsapp_path, alert: t("dashboard.whatsapp_channels.callback_error")
      end

      # POST /whatsapp
      # Handles manual setup form submission
      def create
        unless current_account.within_limit?(:channels)
          redirect_to channels_whatsapp_index_path, alert: t("dashboard.whatsapp_channels.limit_reached")
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "whatsapp",
          channel_params: whatsapp_channel_create_params.merge(provider_embedded_signup: false),
          current_account: current_account
        )

        if creator.call
          @whatsapp_channel = creator.channel
          redirect_to edit_channels_whatsapp_path(@whatsapp_channel), notice: t("dashboard.whatsapp_channels.created"), status: :see_other
        else
          redirect_to new_channels_whatsapp_path, alert: t("dashboard.whatsapp_channels.create_failed"), status: :see_other
        end
      end

      def edit; end

      def update
        current_account.with_shard do
          if @whatsapp_channel.update(whatsapp_channel_update_params)
            redirect_to channels_whatsapp_index_path, notice: t("dashboard.whatsapp_channels.updated"), status: :see_other
          else
            render :edit, status: :unprocessable_entity
          end
        end
      end

      def destroy
        current_account.with_shard do
          @whatsapp_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to channels_whatsapp_index_path, notice: t("dashboard.whatsapp_channels.destroyed") }
          format.turbo_stream { render turbo_stream: turbo_stream.remove(@whatsapp_channel) }
        end
      end

      # POST /whatsapp/:id/reconnect
      def reconnect
        current_account.with_shard do
          @whatsapp_channel.reauthorized!
        end
        
        # If it was an embedded setup, a true token refresh might require the FB SDK.
        # But clearing the flag lets the system try again. If it fails 3 times, it will suspend again.
        redirect_back fallback_location: edit_channels_whatsapp_path(@whatsapp_channel), 
                      notice: t("dashboard.whatsapp_channels.reconnected", default: "Channel re-activated successfully. If your access token is truly expired, please update it.")
      end

      private

      def set_whatsapp_channel
        current_account.with_shard do
          @whatsapp_channel = Channel::Whatsapp.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_whatsapp_channel
        authorize :whatsapp_channel
      end

      def whatsapp_channel_create_params
        params.require(:channel_whatsapp).permit(
          :name, :phone_code, :phone_number, :full_phone_number,
          :phone_number_id, :business_account_id, :api_key
        ).to_h
      end

      def whatsapp_channel_update_params
        params.require(:channel_whatsapp).permit(
          :name,
          primary_inbox_attributes: [
            :id, :reopen_window_seconds, :csat_survey_enabled, :csat_survey_id,
            sla_policy_ids: []
          ]
        )
      end
    end
  end
end
