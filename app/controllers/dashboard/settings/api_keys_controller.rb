# frozen_string_literal: true

module Dashboard
  module Settings
    class ApiKeysController < DashboardController
      before_action :set_api_key, only: [:destroy]
      
      def index
        authorize :api_key, :index?
        @api_keys = current_account.access_tokens.where(token_type: :api_key).order(created_at: :desc)
      end

      def create
        authorize :api_key, :create?
        
        token = current_account.access_tokens.build(
          token_type: :api_key,
          token: SecureRandom.hex(32)
        )

        if token.save
          redirect_to settings_api_keys_path, notice: t("dashboard.settings.api_keys.created", default: "API Key generated successfully.")
        else
          redirect_to settings_api_keys_path, alert: t("dashboard.settings.api_keys.create_failed", default: "Failed to generate API Key.")
        end
      end

      def destroy
        authorize :api_key, :destroy?
        @api_key.destroy
        redirect_to settings_api_keys_path, notice: t("dashboard.settings.api_keys.destroyed", default: "API Key revoked successfully.")
      end

      private

      def set_api_key
        @api_key = current_account.access_tokens.find_by!(id: params[:id], token_type: :api_key)
      end
    end
  end
end
