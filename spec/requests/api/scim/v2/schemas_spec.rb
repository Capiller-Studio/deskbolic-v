# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Scim::V2::Schemas", type: :request do
  let(:headers) { { "Content-Type" => "application/scim+json" } }

  describe "GET /api/scim/v2/schemas" do
    it "returns all supported schemas without authentication" do
      get "/api/scim/v2/schemas", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      expect(json["totalResults"]).to eq(2)

      schema_ids = json["Resources"].map { |s| s["id"] }
      expect(schema_ids).to include("urn:ietf:params:scim:schemas:core:2.0:User")
      expect(schema_ids).to include("urn:ietf:params:scim:schemas:core:2.0:Group")
    end
  end

  describe "GET /api/scim/v2/schemas/:id" do
    it "returns the User schema" do
      get "/api/scim/v2/schemas/urn:ietf:params:scim:schemas:core:2.0:User", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq("urn:ietf:params:scim:schemas:core:2.0:User")
      expect(json["name"]).to eq("User")

      attr_names = json["attributes"].map { |a| a["name"] }
      expect(attr_names).to include("userName", "name", "emails", "active", "displayName")
    end

    it "returns 404 for unknown schema" do
      get "/api/scim/v2/schemas/urn:unknown:schema", headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
    end
  end
end
