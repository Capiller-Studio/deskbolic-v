# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Scim::V2::ResourceTypes", type: :request do
  let(:headers) { { "Content-Type" => "application/scim+json" } }

  describe "GET /api/scim/v2/resource_types" do
    it "returns the list of resource types without authentication" do
      get "/api/scim/v2/resource_types", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      expect(json["totalResults"]).to eq(2)

      user_type = json["Resources"].find { |r| r["id"] == "User" }
      expect(user_type).to be_present
      expect(user_type["endpoint"]).to eq("/api/scim/v2/users")
      expect(user_type["schema"]).to eq("urn:ietf:params:scim:schemas:core:2.0:User")

      group_type = json["Resources"].find { |r| r["id"] == "Group" }
      expect(group_type).to be_present
      expect(group_type["endpoint"]).to eq("/api/scim/v2/groups")
    end
  end

  describe "GET /api/scim/v2/resource_types/:id" do
    it "returns a specific resource type" do
      get "/api/scim/v2/resource_types/User", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq("User")
      expect(json["name"]).to eq("User")
    end

    it "returns 404 for unknown resource type" do
      get "/api/scim/v2/resource_types/Unknown", headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
    end
  end
end
