# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: %i[google_oauth2 facebook]

    def google_oauth2
      handle_social_login(:google)
    end

    def facebook
      handle_social_login(:facebook)
    end

    def failure
      Auth::AuditLog.log(
        event_type:    :login_failure,
        auth_method:   failed_strategy.name.to_sym,
        status:        :failure,
        error_code:    failure_message,
        error_message: "Social login failed: #{failure_message}"
      ) rescue nil

      redirect_to(new_user_session_path, alert: I18n.t(
        "auth.social.failure",
        default: "Could not authenticate via social login: %{message}",
        message: failure_message
      ))
    end

    private

    def handle_social_login(provider)
      auth_hash = request.env["omniauth.auth"]
      if auth_hash.blank?
        redirect_to(new_user_session_path, alert: I18n.t("auth.social.missing_auth", default: "Authentication data not received from provider."))
        return
      end

      # Resolve tenant if signing in through tenant subdomain
      tenant_account = nil
      if request.subdomain.present? && request.subdomain != "www"
        tenant_account = Account.find_by(identifier: request.subdomain)
      end

      first_name = auth_hash.info&.first_name || auth_hash.info&.name&.split(" ")&.first
      last_name  = auth_hash.info&.last_name  || auth_hash.info&.name&.split(" ")&.drop(1)&.join(" ")

      resolution = Auth::IdentityResolver.call(
        provider:         provider,
        uid:              auth_hash.uid,
        email:            auth_hash.info&.email,
        account:          tenant_account,
        first_name:       first_name,
        last_name:        last_name,
        credentials:      auth_hash.credentials&.to_h || {},
        extra_attributes: auth_hash.extra&.to_h || {}
      )

      if resolution.success?
        user = resolution.user

        Auth::AuditLog.log(
          event_type:  :login_success,
          auth_method: provider,
          status:      :success,
          account:     tenant_account,
          user:        user,
          email:       user.email,
          metadata:    {
            provider:    provider,
            uid:         auth_hash.uid,
            provisioned: resolution.provisioned?
          }
        )

        sign_in_and_redirect(user, event: :authentication)
        set_flash_message(:notice, :success, kind: provider.to_s.titleize) if is_navigational_format?
      else
        Auth::AuditLog.log(
          event_type:    :login_failure,
          auth_method:   provider,
          status:        :failure,
          account:       tenant_account,
          email:         auth_hash.info&.email,
          error_code:    resolution.error_code,
          error_message: resolution.error_message
        )

        redirect_to(new_user_session_path, alert: I18n.t(
          "auth.social.error",
          default: "Authentication failed: %{message}",
          message: resolution.error_message
        ))
      end
    end
  end
end
