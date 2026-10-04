# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth::Saml::Sessions", type: :request do
  let(:cert_pem) { AuthTestCertificateHelper.generate_pem }
  let(:account)  { create(:account, identifier: "acme", name: "Acme Corp") }
  let!(:config) do
    create(
      :auth_sso_configuration,
      account:                  account,
      idp_entity_id:            "http://www.okta.com/exk123",
      idp_sso_url:              "https://okta.com/app/sso",
      idp_certificates:         [ cert_pem ],
      allowed_email_domains:    [ "acmecorp.com" ],
      status:                   :active,
      jit_provisioning_enabled: true
    )
  end

  describe "GET /auth/saml/metadata" do
    it "renders XML metadata for valid account" do
      get "/auth/saml/metadata", params: { account: "acme" }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("samlmetadata+xml")
      expect(response.body).to include("EntityDescriptor")
      expect(response.body).to include("/auth/saml/consume")
    end

    it "returns 404 when account does not exist" do
      get "/auth/saml/metadata", params: { account: "nonexistent" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /auth/saml/initiate" do
    it "redirects to IdP SSO URL with RelayState" do
      get "/auth/saml/initiate", params: { account: "acme" }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to start_with("https://okta.com/app/sso")
      expect(response.location).to include("SAMLRequest=")
      expect(response.location).to include("RelayState=")
    end

    it "redirects to login with alert if SSO is inactive" do
      config.update!(status: :inactive)
      get "/auth/saml/initiate", params: { account: "acme" }

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /auth/saml/consume (ACS endpoint)" do
    it "redirects to login with alert when SAMLResponse is missing" do
      post "/auth/saml/consume"

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end

    context "with mocked valid SAML response" do
      let(:mock_validation) do
        Auth::Saml::ResponseValidator::ValidationResult.new(
          success:       true,
          name_id:       "john.sso@acmecorp.com",
          email:         "john.sso@acmecorp.com",
          first_name:    "John",
          last_name:     "SSO",
          groups:        [ "Engineering" ],
          attributes:    { "email" => [ "john.sso@acmecorp.com" ] },
          error_code:    nil,
          error_message: nil
        )
      end

      before do
        allow(Auth::Saml::ResponseValidator).to receive(:call).and_return(mock_validation)
      end

      it "provisions JIT user, logs in, and redirects to dashboard" do
        relay_state = { account_id: account.id, return_to: "/conversations" }.to_json

        expect do
          post "/auth/saml/consume", params: {
            SAMLResponse: "dummy_valid_base64_response",
            RelayState:   relay_state
          }
        end.to change(User, :count).by(1)
           .and change(Auth::UserIdentity, :count).by(1)

        expect(response).to redirect_to("/conversations")
        expect(session[:sso_signed_in_at]).to be_present
        expect(session[:sso_account_id]).to eq(account.id)

        user = User.find_by(email: "john.sso@acmecorp.com")
        expect(user).to be_present
        expect(controller.current_user).to eq(user)

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("login_success")
        expect(audit_log.auth_method).to eq("saml")
      end

      it "supports IdP-initiated login by resolving issuer entity ID" do
        mock_saml_doc = instance_double(OneLogin::RubySaml::Response, issuers: [ "http://www.okta.com/exk123" ])
        allow(OneLogin::RubySaml::Response).to receive(:new).and_return(mock_saml_doc)

        post "/auth/saml/consume", params: { SAMLResponse: "dummy_idp_initiated_response" }

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("acme.deskbolic.app")

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("login_success")
      end
    end

    context "when SAML validation fails" do
      let(:mock_failure) do
        Auth::Saml::ResponseValidator::ValidationResult.new(
          success:       false,
          name_id:       "tampered@acmecorp.com",
          email:         "tampered@acmecorp.com",
          first_name:    nil,
          last_name:     nil,
          groups:        [],
          attributes:    {},
          error_code:    "invalid_signature",
          error_message: "Signature check failed"
        )
      end

      before do
        allow(Auth::Saml::ResponseValidator).to receive(:call).and_return(mock_failure)
      end

      it "logs failure and redirects to login" do
        relay_state = { account_id: account.id }.to_json

        post "/auth/saml/consume", params: {
          SAMLResponse: "tampered_response",
          RelayState:   relay_state
        }

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to include("Signature check failed")

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("login_failure")
        expect(audit_log.error_code).to eq("invalid_signature")
      end
    end
  end
end
