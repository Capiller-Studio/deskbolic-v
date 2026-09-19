# frozen_string_literal: true

module Dashboard
  module Settings
    class SsoController < DashboardController
      before_action :ensure_sso_feature_enabled
      before_action :set_sso_config

      def show
        authorize(:sso, :show?, policy_class: Dashboard::SsoPolicy)

        @domain_verifications = current_account.domain_verifications.order(created_at: :desc)
        @scim_tokens          = current_account.scim_tokens.order(created_at: :desc)
        @audit_logs           = current_account.auth_audit_logs.recent.limit(30)
        @sp_metadata_url      = auth_saml_metadata_url(account: current_account.identifier)
        @sp_acs_url           = auth_saml_consume_url(account: current_account.identifier)
        @sp_entity_id         = @sp_metadata_url

        @roles = current_account.with_shard { current_account.roles.order(:name).to_a }
      end

      def update
        authorize(:sso, :update?, policy_class: Dashboard::SsoPolicy)

        if @sso_config.update(sso_config_params)
          Auth::AuditLog.log(
            event_type:  :sso_config_changed,
            auth_method: @sso_config.saml? ? :saml : :oidc,
            status:      :success,
            account:     current_account,
            user:        current_user,
            metadata:    { status: @sso_config.status, protocol: @sso_config.protocol }
          )

          redirect_to(settings_sso_path, notice: I18n.t("dashboard.settings.sso.updated", default: "Single Sign-On settings updated successfully."))
        else
          @domain_verifications = current_account.domain_verifications.order(created_at: :desc)
          @scim_tokens          = current_account.scim_tokens.order(created_at: :desc)
          @audit_logs           = current_account.auth_audit_logs.recent.limit(30)
          @sp_metadata_url      = auth_saml_metadata_url(account: current_account.identifier)
          @sp_acs_url           = auth_saml_consume_url(account: current_account.identifier)
          @sp_entity_id         = @sp_metadata_url
          @roles                = current_account.with_shard { current_account.roles.order(:name).to_a }

          flash.now[:alert] = @sso_config.errors.full_messages.to_sentence
          render(:show, status: :unprocessable_entity)
        end
      end

      private

      def ensure_sso_feature_enabled
        unless current_account.feature_enabled?(:sso)
          redirect_to(settings_general_path, alert: I18n.t("dashboard.settings.sso.plan_required", default: "Enterprise SSO is available on the Parabolic plan. Please upgrade your subscription."))
        end
      end

      def set_sso_config
        @sso_config = current_account.sso_configuration || current_account.build_sso_configuration(
          protocol:                 :saml,
          provider_type:            :okta,
          status:                   :inactive,
          jit_provisioning_enabled: true,
          allow_owner_password_fallback: true
        )
      end

      def sso_config_params
        p = params.expect(
          auth_sso_configuration: [ :protocol,
          :provider_type,
          :status,
          :idp_entity_id,
          :idp_sso_url,
          :idp_slo_url,
          :idp_metadata_url,
          :oidc_issuer,
          :oidc_client_id,
          :oidc_client_secret,
          :enforce_sso,
          :jit_provisioning_enabled,
          :allow_owner_password_fallback,
          :session_timeout_hours,
          :default_role_id,
          :idp_certificate_raw,
          :allowed_email_domains_raw ]
        )

        if p.key?(:idp_certificate_raw)
          p[:idp_certificates] = p.delete(:idp_certificate_raw).to_s.split(/(?=-----BEGIN CERTIFICATE-----)/).map(&:strip).compact_blank
        end

        if p.key?(:allowed_email_domains_raw)
          p[:allowed_email_domains] = p.delete(:allowed_email_domains_raw).to_s.split(/[,\s\n\r]+/).map(&:strip).compact_blank
        end

        p.delete(:oidc_client_secret) if p[:oidc_client_secret].blank?

        p
      end
    end
  end
end
