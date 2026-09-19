# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Scim::V2::ServiceProviderConfig", type: :request do
  let(:headers) { { "Content-Type" => "application/scim+json" } }

  describe "GET /api/scim/v2/service_provider_config" do
    it "returns the service provider configuration without authentication" do
      get "/api/scim/v2/service_provider_config", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig")
      expect(json["patch"]["supported"]).to be true
      expect(json["bulk"]["supported"]).to be false
      expect(json["filter"]["supported"]).to be true
      expect(json["filter"]["maxResults"]).to eq(100)
      expect(json["authenticationSchemes"]).to be_an(Array)
      expect(json["authenticationSchemes"].first["type"]).to eq("oauthbearertoken")
      expect(json["meta"]["resourceType"]).to eq("ServiceProviderConfig")
    end
  end
end
