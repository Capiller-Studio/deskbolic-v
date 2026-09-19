# frozen_string_literal: true

module Dashboard
  module Settings
    class DomainVerificationsController < DashboardController
      before_action :ensure_sso_feature_enabled
      before_action :set_verification, only: %i[verify destroy]

      def index
        authorize(:domain_verification, :index?, policy_class: Dashboard::DomainVerificationPolicy)
        @domain_verifications = current_account.domain_verifications.order(created_at: :desc)
        redirect_to(settings_sso_path)
      end

      def create
        authorize(:domain_verification, :create?, policy_class: Dashboard::DomainVerificationPolicy)

        domain = params.dig(:auth_domain_verification, :domain).to_s.strip.downcase
        @verification = current_account.domain_verifications.build(domain: domain)

        if @verification.save
          redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.domains.added", default: "Domain added. Please configure DNS TXT record to verify ownership."))
        else
          redirect_to(settings_sso_path, alert: @verification.errors.full_messages.to_sentence)
        end
      end

      def verify
        authorize(:domain_verification, :verify?, policy_class: Dashboard::DomainVerificationPolicy)

        result = Auth::DnsVerifier.call(@verification)
        if result[:verified]
          redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.domains.verified_notice", domain: @verification.domain, default: "Domain '#{@verification.domain}' verified successfully! It is now active for SSO."))
        else
          redirect_to(settings_sso_path, alert: I18n.t("dashboard.settings.domains.verification_failed", reason: result[:reason], default: "Verification failed: %{reason}"))
        end
      end

      def destroy
        authorize(:domain_verification, :destroy?, policy_class: Dashboard::DomainVerificationPolicy)

        domain_name = @verification.domain
        @verification.destroy

        # Also remove from allowed_email_domains on SSO config
        sso_config = current_account.sso_configuration
        if sso_config.present? && sso_config.allowed_email_domains.include?(domain_name)
          sso_config.allowed_email_domains.delete(domain_name)
          sso_config.save
        end

        redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.domains.removed", default: "Domain removed successfully."))
      end

      private

      def ensure_sso_feature_enabled
        unless current_account.feature_enabled?(:sso)
          redirect_to(settings_general_path, alert: I18n.t("dashboard.settings.sso.plan_required", default: "Enterprise SSO is available on the Parabolic plan."))
        end
      end

      def set_verification
        @verification = current_account.domain_verifications.find(params[:id])
      end
    end
  end
end
