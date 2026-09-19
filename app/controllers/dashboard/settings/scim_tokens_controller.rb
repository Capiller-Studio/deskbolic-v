# frozen_string_literal: true

module Dashboard
  module Settings
    class ScimTokensController < DashboardController
      before_action :ensure_sso_feature_enabled

      def index
        authorize(:scim_token, :index?, policy_class: Dashboard::ScimTokenPolicy)
        redirect_to(settings_sso_path)
      end

      def create
        authorize(:scim_token, :create?, policy_class: Dashboard::ScimTokenPolicy)

        name = params.dig(:auth_scim_token, :name).presence || "Directory Sync (#{Time.current.strftime('%Y-%m-%d')})"
        record, raw_token = Auth::ScimToken.generate_for_account(current_account, name: name)

        flash[:new_scim_token] = raw_token
        redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.scim.created", default: "SCIM Token created! Copy your secret token now — it will not be shown again."))
      end

      def destroy
        authorize(:scim_token, :destroy?, policy_class: Dashboard::ScimTokenPolicy)

        token = current_account.scim_tokens.find(params[:id])
        token.destroy

        redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.scim.revoked", default: "SCIM Token revoked."))
      end

      private

      def ensure_sso_feature_enabled
        unless current_account.feature_enabled?(:sso)
          redirect_to(settings_general_path, alert: I18n.t("dashboard.settings.sso.plan_required", default: "SCIM Directory Sync is available on the Parabolic plan."))
        end
      end
    end
  end
end
