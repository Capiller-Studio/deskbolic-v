# frozen_string_literal: true

module Dashboard
  module Channels
    class ApiController < DashboardController
      before_action :set_api_channel, only: %i[edit update destroy]
      before_action :authorize_api_channel

      def index
        @api_channels = current_account.with_shard do
          Channel::Api.where(account: current_account).includes(:inboxes).order(created_at: :desc)
        end
      end

      def new
        @api_channel = Channel::Api.new
      end

      def create
        unless current_account.within_limit?(:channels)
          redirect_to channels_api_index_path, alert: t("dashboard.api_channels.limit_reached", default: "Channel limit reached")
          return
        end

        creator = ::Channels::ChannelCreator.new(
          channel_type: "api",
          channel_params: api_channel_create_params,
          current_account: current_account
        )

        if creator.call
          @api_channel = creator.channel
          redirect_to edit_channels_api_path(@api_channel), notice: t("dashboard.api_channels.created", default: "API Channel created")
        else
          redirect_to new_channels_api_path, alert: t("dashboard.api_channels.create_failed", default: "Failed to create API Channel")
        end
      end

      def edit; end

      def update
        current_account.with_shard do
          if @api_channel.update(api_channel_update_params)
            redirect_to channels_api_index_path, notice: t("dashboard.api_channels.updated", default: "API Channel updated")
          else
            render :edit, status: :unprocessable_entity
          end
        end
      end

      def destroy
        current_account.with_shard do
          @api_channel.destroy
        end
        current_account.decrement_usage!(:channels)

        respond_to do |format|
          format.html { redirect_to channels_api_index_path, notice: t("dashboard.api_channels.destroyed", default: "API Channel deleted") }
          format.turbo_stream { render turbo_stream: turbo_stream.remove(@api_channel) }
        end
      end

      private

      def set_api_channel
        current_account.with_shard do
          @api_channel = Channel::Api.find_by!(id: params[:id], account: current_account)
        end
      end

      def authorize_api_channel
        authorize :api_channel
      end

      def api_channel_create_params
        params.require(:channel_api).permit(:name, :description, :webhook_url).to_h
      end

      def api_channel_update_params
        params.require(:channel_api).permit(
          :name, :description, :webhook_url,
          primary_inbox_attributes: [
            :id, :reopen_window_seconds, :csat_survey_enabled, :csat_survey_id,
            sla_policy_ids: []
          ]
        )
      end
    end
  end
end
