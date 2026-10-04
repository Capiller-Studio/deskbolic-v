# frozen_string_literal: true

require "onelogin/ruby-saml"

module Auth
  module Saml
    class SessionsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [ :consume ]

      def metadata
        sso_config = resolve_sso_config
        return head(:not_found) unless sso_config&.saml?

        settings = Auth::Saml::SettingsBuilder.call(sso_config, request.base_url)
        meta = OneLogin::RubySaml::Metadata.new

        render(xml: meta.generate(settings, true), content_type: "application/samlmetadata+xml")
      end

      def initiate
        sso_config = resolve_sso_config
        unless sso_config&.active? && sso_config.saml?
          redirect_to(new_user_session_path, alert: I18n.t("auth.sso.not_configured", default: "Single Sign-On is not configured or active for this organization."))
          return
        end

        settings = Auth::Saml::SettingsBuilder.call(sso_config, request.base_url)
        saml_request = OneLogin::RubySaml::Authrequest.new

        # Encode return destination and account id into RelayState
        relay_state = build_relay_state(sso_config)

        redirect_to(saml_request.create(settings, RelayState: relay_state), allow_other_host: true)
      end

      def consume
        raw_response = params[:SAMLResponse]
        if raw_response.blank?
          redirect_to(new_user_session_path, alert: I18n.t("auth.sso.missing_response", default: "Invalid SSO response received from Identity Provider."))
          return
        end

        sso_config = resolve_sso_config_for_response(raw_response)
        unless sso_config&.active? && sso_config.saml?
          Auth::AuditLog.log(
            event_type:    :login_failure,
            auth_method:   :saml,
            status:        :failure,
            error_code:    "sso_config_not_found",
            error_message: "SSO configuration not found or inactive for SAML response"
          )
          redirect_to(new_user_session_path, alert: I18n.t("auth.sso.inactive", default: "SSO is inactive or not configured for this account."))
          return
        end

        # Validate assertion
        validation = Auth::Saml::ResponseValidator.call(raw_response, sso_config, request.base_url)
        if validation.failure?
          Auth::AuditLog.log(
            event_type:    :login_failure,
            auth_method:   :saml,
            status:        :failure,
            account:       sso_config.account,
            email:         validation.email || validation.name_id,
            error_code:    validation.error_code,
            error_message: validation.error_message
          )
          redirect_to(new_user_session_path, alert: I18n.t("auth.sso.verification_failed", reason: validation.error_message, default: "SSO Authentication failed: #{validation.error_message}"))
          return
        end

        # Resolve or JIT-provision user
        resolution = Auth::IdentityResolver.call(
          provider:         :saml,
          uid:              validation.name_id,
          email:            validation.email,
          account:          sso_config.account,
          first_name:       validation.first_name,
          last_name:        validation.last_name,
          extra_attributes: validation.attributes.merge(groups: validation.groups)
        )

        if resolution.failure?
          Auth::AuditLog.log(
            event_type:    :login_failure,
            auth_method:   :saml,
            status:        :failure,
            account:       sso_config.account,
            email:         validation.email,
            error_code:    resolution.error_code,
            error_message: resolution.error_message
          )
          redirect_to(new_user_session_path, alert: I18n.t("auth.sso.provisioning_failed", reason: resolution.error_message, default: "Could not provision account: #{resolution.error_message}"))
          return
        end

        user = resolution.user

        # Audit successful login
        Auth::AuditLog.log(
          event_type:  :login_success,
          auth_method: :saml,
          status:      :success,
          account:     sso_config.account,
          user:        user,
          email:       validation.email,
          metadata:    {
            idp_entity_id: sso_config.idp_entity_id,
            name_id:       validation.name_id,
            provisioned:   resolution.provisioned?
          }
        )

        # Store session metadata for governance & timeout enforcement
        session[:sso_signed_in_at]   = Time.current.to_i
        session[:sso_account_id]     = sso_config.account_id
        session[:sso_timeout_hours]  = sso_config.session_timeout_hours

        # Sign in with Devise
        sign_in(:user, user)

        # Determine target redirect path
        target_url = resolve_redirect_destination(sso_config)
        redirect_to(target_url, allow_other_host: true, notice: I18n.t("auth.sso.success", default: "Signed in successfully via Single Sign-On."))
      end

      private

      def resolve_sso_config
        # 1. By account subdomain
        if request.subdomain.present? && request.subdomain != "www"
          account = Account.find_by(identifier: request.subdomain)
          return account.sso_configuration if account&.sso_configuration.present?
        end

        # 2. By account_id or identifier param
        if params[:account_id].present?
          account = Account.find_by(id: params[:account_id])
          return account.sso_configuration if account&.sso_configuration.present?
        end

        if params[:account].present?
          account = Account.find_by(identifier: params[:account])
          return account.sso_configuration if account&.sso_configuration.present?
        end

        # 3. By email domain
        if params[:email].present?
          lookup = Auth::DomainLookupService.call(params[:email])
          if lookup[:account_id].present?
            return Auth::SsoConfiguration.find_by(account_id: lookup[:account_id])
          end
        end

        nil
      end

      def resolve_sso_config_for_response(raw_response)
        # 1. First check if subdomain exists
        config = resolve_sso_config
        return config if config.present?

        # 2. Check RelayState for account_id
        if params[:RelayState].present?
          account_id = parse_account_from_relay_state(params[:RelayState])
          if account_id.present?
            config = Auth::SsoConfiguration.find_by(account_id: account_id)
            return config if config.present?
          end
        end

        # 3. IdP-Initiated Login: extract Issuer from SAMLResponse XML
        begin
          saml_doc = OneLogin::RubySaml::Response.new(raw_response)
          issuer = Array(saml_doc.issuers).first
          if issuer.present?
            return Auth::SsoConfiguration.find_by(idp_entity_id: issuer, status: :active)
          end
        rescue StandardError => e
          Rails.logger.warn("Failed to extract issuer from SAML response: #{e.message}")
        end

        nil
      end

      def build_relay_state(sso_config)
        return_to = params[:return_to].presence || params[:RelayState].presence
        {
          account_id: sso_config.account_id,
          return_to:  return_to
        }.to_json
      end

      def parse_account_from_relay_state(relay_state)
        data = JSON.parse(relay_state)
        data["account_id"]
      rescue JSON::ParserError
        nil
      end

      def resolve_redirect_destination(sso_config)
        # Check RelayState return_to
        if params[:RelayState].present?
          begin
            data = JSON.parse(params[:RelayState])
            if data["return_to"].present? && data["return_to"].start_with?("/")
              return data["return_to"]
            end
          rescue JSON::ParserError
            # Non-JSON relay state
            return params[:RelayState] if params[:RelayState].start_with?("/")
          end
        end

        # Default redirect to account tenant dashboard
        app_domain = ENV.fetch("APP_DOMAIN", "deskbolic.app")
        "https://#{sso_config.account.identifier}.#{app_domain}/"
      end
    end
  end
end
