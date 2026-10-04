# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Scim::V2::GroupsController", type: :request do
  let(:plan) { create(:plan, features: { "sso" => true, "scim" => true }) }
  let(:account) { create(:account) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:sso_config) { create(:auth_sso_configuration, account: account) }

  let(:token_result) { Auth::ScimToken.generate_for_account(account, name: "Okta SCIM") }
  let(:scim_token_record) { token_result.first }
  let(:raw_token) { token_result.second }

  let(:auth_headers) do
    {
      "Authorization" => "Bearer #{raw_token}",
      "Content-Type"  => "application/scim+json"
    }
  end

  let(:member_user) { create(:user, email: "agent@acme.com", first_name: "Jane", last_name: "Doe") }
  let!(:member_account_user) { create(:account_user, account: account, user: member_user, status: :active) }

  let!(:team) do
    account.with_shard { create(:team, account: account, name: "Engineering") }
  end

  describe "GET /api/scim/v2/groups" do
    it "returns a SCIM ListResponse of workspace groups" do
      get "/api/scim/v2/groups", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["schemas"]).to contain_exactly("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      expect(body["totalResults"]).to eq(1)
      expect(body["Resources"].size).to eq(1)
      expect(body["Resources"].first["displayName"]).to eq("Engineering")
    end

    it "filters groups by displayName" do
      account.with_shard { create(:team, account: account, name: "Design") }

      get "/api/scim/v2/groups", params: { filter: 'displayName eq "Engineering"' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["totalResults"]).to eq(1)
      expect(body["Resources"].first["displayName"]).to eq("Engineering")
    end
  end

  describe "GET /api/scim/v2/groups/:id" do
    it "returns SCIM Group details with members" do
      account.with_shard do
        create(:team_user, team: team, user: member_user)
      end

      get "/api/scim/v2/groups/#{team.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(team.id)
      expect(body["displayName"]).to eq("Engineering")
      expect(body["members"].size).to eq(1)
      expect(body["members"].first["value"]).to eq(member_user.id)
    end

    it "returns 404 for nonexistent group" do
      get "/api/scim/v2/groups/#{SecureRandom.uuid}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/scim/v2/groups" do
    let(:create_payload) do
      {
        schemas: [ "urn:ietf:params:scim:schemas:core:2.0:Group" ],
        displayName: "Support",
        members: [
          { value: member_user.id }
        ]
      }.to_json
    end

    it "creates a new group and syncs members" do
      expect {
        post "/api/scim/v2/groups", params: create_payload, headers: auth_headers
      }.to change { account.with_shard { account.teams.count } }.by(1)

      expect(response).to have_http_status(:created)
      expect(response.headers["Location"]).to be_present

      body = JSON.parse(response.body)
      expect(body["displayName"]).to eq("Support")
      expect(body["members"].size).to eq(1)
    end

    it "returns 409 Conflict if group already exists" do
      duplicate_payload = {
        schemas: [ "urn:ietf:params:scim:schemas:core:2.0:Group" ],
        displayName: "Engineering"
      }.to_json

      post "/api/scim/v2/groups", params: duplicate_payload, headers: auth_headers

      expect(response).to have_http_status(:conflict)
      body = JSON.parse(response.body)
      expect(body["scimType"]).to eq("uniqueness")
    end

    it "returns 400 when displayName is missing" do
      invalid_payload = {
        schemas: [ "urn:ietf:params:scim:schemas:core:2.0:Group" ]
      }.to_json

      post "/api/scim/v2/groups", params: invalid_payload, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PUT /api/scim/v2/groups/:id" do
    it "replaces the group name and members" do
      put_payload = {
        schemas: [ "urn:ietf:params:scim:schemas:core:2.0:Group" ],
        displayName: "Platform Team",
        members: [ { value: member_user.id } ]
      }.to_json

      put "/api/scim/v2/groups/#{team.id}", params: put_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["displayName"]).to eq("Platform Team")
      expect(body["members"].size).to eq(1)
    end
  end

  describe "PATCH /api/scim/v2/groups/:id" do
    it "renames a group via replace operation" do
      patch_payload = {
        schemas: [ "urn:ietf:params:scim:api:messages:2.0:PatchOp" ],
        Operations: [
          { op: "replace", path: "displayName", value: "Backend" }
        ]
      }.to_json

      patch "/api/scim/v2/groups/#{team.id}", params: patch_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["displayName"]).to eq("Backend")
    end

    it "adds members via add operation" do
      patch_payload = {
        schemas: [ "urn:ietf:params:scim:api:messages:2.0:PatchOp" ],
        Operations: [
          { op: "add", path: "members", value: [ { value: member_user.id } ] }
        ]
      }.to_json

      patch "/api/scim/v2/groups/#{team.id}", params: patch_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["members"].any? { |m| m["value"] == member_user.id }).to be true
    end

    it "removes members via remove operation" do
      account.with_shard do
        create(:team_user, team: team, user: member_user)
      end

      patch_payload = {
        schemas: [ "urn:ietf:params:scim:api:messages:2.0:PatchOp" ],
        Operations: [
          { op: "remove", path: "members[value eq \"#{member_user.id}\"]" }
        ]
      }.to_json

      patch "/api/scim/v2/groups/#{team.id}", params: patch_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["members"]).to be_empty
    end
  end

  describe "DELETE /api/scim/v2/groups/:id" do
    it "deletes the group and returns 204 No Content" do
      delete "/api/scim/v2/groups/#{team.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      account.with_shard do
        expect(Team.exists?(team.id)).to be false
      end
    end
  end
end
