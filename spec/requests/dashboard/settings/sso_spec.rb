# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard::Settings::SsoController", type: :request do
  let(:plan) { create(:plan, features: { "sso" => true, "scim" => true }) }
  let(:account) { create(:account) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:owner_user) { create(:user, password: "password123", confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe "GET /settings/sso" do
    context "when SSO feature is not included in plan" do
      let(:plan) { create(:plan, features: { "sso" => false }) }

      it "redirects to settings general page with an alert" do
        get settings_sso_path(locale: :en)
        expect(response).to redirect_to(settings_general_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when SSO feature is enabled" do
      it "renders the SSO configuration page successfully" do
        get settings_sso_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Single Sign-On")
        expect(response.body).to include("Service Provider")
      end

      it "renders existing SSO configuration when present" do
        create(:auth_sso_configuration, account: account, idp_entity_id: "https://okta.com/exk999")

        get settings_sso_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("https://okta.com/exk999")
      end
    end
  end

  describe "PATCH /settings/sso" do
    let(:pem_cert) { AuthTestCertificateHelper.generate_pem }

    context "with valid parameters" do
      let(:valid_params) do
        {
          auth_sso_configuration: {
            protocol: "saml",
            provider_type: "okta",
            status: "active",
            idp_entity_id: "https://okta.com/exk123",
            idp_sso_url: "https://okta.com/app/sso",
            idp_certificate_raw: pem_cert,
            allowed_email_domains_raw: "acme.com, corp.acme.com",
            enforce_sso: "1",
            jit_provisioning_enabled: "1",
            allow_owner_password_fallback: "1",
            session_timeout_hours: "24"
          }
        }
      end

      it "creates or updates the SSO configuration" do
        patch settings_sso_path(locale: :en), params: valid_params

        expect(response).to redirect_to(settings_sso_path)
        expect(flash[:notice]).to be_present

        config = account.reload.sso_configuration
        expect(config).to be_present
        expect(config.idp_entity_id).to eq("https://okta.com/exk123")
        expect(config.allowed_email_domains).to contain_exactly("acme.com", "corp.acme.com")
        expect(config.enforce_sso).to be true
        expect(config.session_timeout_hours).to eq(24)
      end

      it "logs the configuration change in Auth::AuditLog" do
        expect {
          patch settings_sso_path(locale: :en), params: valid_params
        }.to change(Auth::AuditLog, :count).by(1)

        log = Auth::AuditLog.last
        expect(log.event_type).to eq("sso_config_changed")
        expect(log.account).to eq(account)
        expect(log.user).to eq(owner_user)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          auth_sso_configuration: {
            protocol: "saml",
            idp_entity_id: "",
            idp_sso_url: "not-a-valid-url"
          }
        }
      end

      it "renders :show with unprocessable entity status and error message" do
        patch settings_sso_path(locale: :en), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to be_present
      end
    end
  end
end
