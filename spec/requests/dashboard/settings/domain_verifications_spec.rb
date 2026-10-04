# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard::Settings::DomainVerificationsController", type: :request do
  let(:plan) { create(:plan, features: { "sso" => true }) }
  let(:account) { create(:account) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:owner_user) { create(:user, password: "password123", confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe "POST /settings/domain_verifications" do
    it "creates a new domain verification record in pending state" do
      expect {
        post settings_domain_verifications_path(locale: :en), params: {
          auth_domain_verification: { domain: "corp.acme.com" }
        }
      }.to change(Auth::DomainVerification, :count).by(1)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:notice]).to be_present

      verification = Auth::DomainVerification.last
      expect(verification.domain).to eq("corp.acme.com")
      expect(verification.status).to eq("pending")
      expect(verification.account).to eq(account)
    end

    it "fails gracefully when domain format is invalid" do
      expect {
        post settings_domain_verifications_path(locale: :en), params: {
          auth_domain_verification: { domain: "invalid-domain" }
        }
      }.not_to change(Auth::DomainVerification, :count)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /settings/domain_verifications/:id/verify" do
    let!(:verification) { create(:auth_domain_verification, account: account, domain: "test.acme.com") }

    it "marks domain verified when Auth::DnsVerifier succeeds" do
      allow(Auth::DnsVerifier).to receive(:call).with(verification).and_return({ verified: true })

      post verify_settings_domain_verification_path(id: verification.id, locale: :en)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:notice]).to include("verified successfully")
    end

    it "shows failure reason when DNS check fails" do
      allow(Auth::DnsVerifier).to receive(:call).with(verification).and_return({ verified: false, reason: "TXT record not found" })

      post verify_settings_domain_verification_path(id: verification.id, locale: :en)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:alert]).to include("Verification failed")
    end
  end

  describe "DELETE /settings/domain_verifications/:id" do
    let!(:verification) { create(:auth_domain_verification, account: account, domain: "corp.acme.com") }
    let!(:sso_config) { create(:auth_sso_configuration, account: account, allowed_email_domains: [ "corp.acme.com", "other.com" ]) }

    it "destroys verification record and removes domain from sso_configuration" do
      expect {
        delete settings_domain_verification_path(id: verification.id, locale: :en)
      }.to change(Auth::DomainVerification, :count).by(-1)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:notice]).to be_present
      expect(sso_config.reload.allowed_email_domains).not_to include("corp.acme.com")
      expect(sso_config.allowed_email_domains).to include("other.com")
    end
  end
end
