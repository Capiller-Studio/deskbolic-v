# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class SessionsController < Devise::SessionsController
    layout "auth"

    before_action :check_sso_enforcement, only: [:create]

    def create
      super do |resource|
        if @owner_bypass_authorized && resource.persisted?
          Auth::AuditLog.log(
            event_type:    :bypass_login,
            auth_method:   :password,
            status:        :success,
            account:       @bypass_account,
            user:          resource,
            email:         resource.email,
            metadata:      { reason: "owner_break_glass" }
          )
        end
      end
    end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sign_in_path_for(resource)
      # 1. If signing in on a specific account subdomain
      if request.subdomain.present? && request.subdomain != "www"
        subdomain_account = Account.find_by(identifier: request.subdomain)
        if subdomain_account && resource.accounts.active.exists?(id: subdomain_account.id)
          return root_url(subdomain: subdomain_account.identifier)
        end
      end

      # 2. Apex domain login routing
      active_accounts = resource.accounts.active
      if active_accounts.empty?
        workspace_url(subdomain: "")
      elsif active_accounts.count == 1
        root_url(subdomain: active_accounts.first.identifier)
      else
        workspaces_url(subdomain: "")
      end
    end

    private

    def check_sso_enforcement
      email = params.dig(:user, :email)&.downcase&.strip
      return if email.blank?

      lookup = Auth::DomainLookupService.call(email)
      return unless lookup[:sso_required] && lookup[:enforce_sso]

      account = Account.find_by(id: lookup[:account_id])
      sso_config = account&.sso_configuration
      return unless sso_config&.enforce_sso?

      bypass_requested = params[:bypass_sso] == "true" || params.dig(:user, :bypass_sso) == "true"

      if bypass_requested
        user = User.find_by(email: email)
        is_owner = user.present? && user.account_users.exists?(account_id: account.id, owner: true)

        if is_owner && sso_config.allow_owner_password_fallback?
          @owner_bypass_authorized = true
          @bypass_account = account
          return
        else
          Auth::AuditLog.log(
            event_type:    :login_failure,
            auth_method:   :password,
            status:        :failure,
            account:       account,
            email:         email,
            error_code:    "bypass_denied",
            error_message: "SSO break-glass bypass denied for non-owner"
          )

          redirect_to new_user_session_path, alert: I18n.t(
            "auth.sso.bypass_denied",
            default: "Emergency password bypass is restricted to Account Owners."
          )
          return
        end
      end

      # SSO is enforced and no valid bypass requested -> block password login
      Auth::AuditLog.log(
        event_type:    :login_failure,
        auth_method:   :password,
        status:        :failure,
        account:       account,
        email:         email,
        error_code:    "sso_enforced",
        error_message: "Password authentication blocked because SSO is enforced"
      )

      redirect_to new_user_session_path(email: email), alert: I18n.t(
        "auth.sso.enforced_notice",
        account: lookup[:account_name],
        default: "Single Sign-On is required for #{lookup[:account_name]}. Please sign in with SSO."
      )
    end
  end
end
