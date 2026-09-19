# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth::DomainLookups", type: :request do
  let(:account) { create(:account, name: "Acme Corp", identifier: "acme") }
  let!(:config) do
    create(
      :auth_sso_configuration,
      account:               account,
      allowed_email_domains: ["acmecorp.com"],
      protocol:              :saml,
      provider_type:         :okta,
      status:                :active,
      enforce_sso:           true
    )
  end

  after do
    Auth::DomainLookupService.clear_cache("acmecorp.com")
  end

  describe "GET /auth/domain_lookup" do
    it "returns SSO configuration for verified enterprise domain" do
      get "/auth/domain_lookup", params: { email: "alice@acmecorp.com" }, as: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:sso_required]).to be true
      expect(data[:account_name]).to eq("Acme Corp")
      expect(data[:protocol]).to eq("saml")
      expect(data[:provider_type]).to eq("okta")
    end

    it "returns sso_required: false for regular email" do
      get "/auth/domain_lookup", params: { email: "bob@gmail.com" }, as: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:sso_required]).to be false
    end

    it "returns 422 unprocessable_entity when query is missing" do
      get "/auth/domain_lookup", as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:error]).to eq("missing_parameter")
    end
  end
end
