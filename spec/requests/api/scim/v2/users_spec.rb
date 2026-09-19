# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Scim::V2::UsersController", type: :request do
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

  describe "Authentication & Authorization" do
    it "returns 401 Unauthorized with SCIM error schema when Authorization header is missing" do
      get "/api/scim/v2/users"

      expect(response).to have_http_status(:unauthorized)
      expect(response.content_type).to include("application/scim+json")

      body = JSON.parse(response.body)
      expect(body["schemas"]).to contain_exactly("urn:ietf:params:scim:api:messages:2.0:Error")
      expect(body["status"]).to eq("401")
      expect(body["detail"]).to include("Missing or malformed Authorization header")
    end

    it "returns 401 Unauthorized when token is invalid" do
      get "/api/scim/v2/users", headers: { "Authorization" => "Bearer invalid-token-xyz" }

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("401")
      expect(body["detail"]).to include("Invalid or expired")
    end

    it "returns 401 Unauthorized when token is expired" do
      scim_token_record.update_column(:expires_at, 1.hour.ago)

      get "/api/scim/v2/users", headers: auth_headers

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("401")
    end

    it "returns 403 Forbidden when account plan lacks SCIM and SSO features" do
      plan.update!(features: { "sso" => false, "scim" => false })

      get "/api/scim/v2/users", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("403")
      expect(body["detail"]).to include("not enabled on your workspace plan")
    end

    it "updates last_used_at on successful authentication" do
      expect {
        get "/api/scim/v2/users", headers: auth_headers
      }.to change { scim_token_record.reload.last_used_at }
    end
  end

  describe "GET /api/scim/v2/users" do
    it "returns a SCIM ListResponse of workspace users" do
      get "/api/scim/v2/users", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["schemas"]).to contain_exactly("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      expect(body["totalResults"]).to eq(1)
      expect(body["startIndex"]).to eq(1)
      expect(body["Resources"].size).to eq(1)

      user_resource = body["Resources"].first
      expect(user_resource["id"]).to eq(member_user.id)
      expect(user_resource["userName"]).to eq("agent@acme.com")
      expect(user_resource["active"]).to be true
      expect(user_resource["name"]["givenName"]).to eq("Jane")
      expect(user_resource["name"]["familyName"]).to eq("Doe")
      expect(user_resource["meta"]["resourceType"]).to eq("User")
    end

    it "filters users by userName with RFC 7644 syntax" do
      other_user = create(:user, email: "other@acme.com", first_name: "Bob")
      create(:account_user, account: account, user: other_user)

      get "/api/scim/v2/users", params: { filter: 'userName eq "agent@acme.com"' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["totalResults"]).to eq(1)
      expect(body["Resources"].first["userName"]).to eq("agent@acme.com")
    end
  end

  describe "GET /api/scim/v2/users/:id" do
    it "returns SCIM User details for a valid workspace member" do
      get "/api/scim/v2/users/#{member_user.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(member_user.id)
      expect(body["userName"]).to eq("agent@acme.com")
      expect(body["emails"].first["value"]).to eq("agent@acme.com")
    end

    it "returns 404 Not Found when user does not belong to the workspace" do
      unrelated_user = create(:user, email: "stranger@other.com")

      get "/api/scim/v2/users/#{unrelated_user.id}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("404")
      expect(body["schemas"]).to contain_exactly("urn:ietf:params:scim:api:messages:2.0:Error")
    end
  end

  describe "POST /api/scim/v2/users" do
    let(:create_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        userName: "new.hire@acme.com",
        name: {
          givenName: "Alice",
          familyName: "Smith"
        },
        emails: [
          {
            value: "new.hire@acme.com",
            type: "work",
            primary: true
          }
        ],
        active: true
      }.to_json
    end

    it "provisions a new user into the workspace and logs to Auth::AuditLog" do
      expect {
        post "/api/scim/v2/users", params: create_payload, headers: auth_headers
      }.to change(User, :count).by(1)
       .and change(AccountUser, :count).by(1)
       .and change(Auth::AuditLog, :count).by(2) # 1 jit_user_created + 1 scim_user_created

      expect(response).to have_http_status(:created)
      expect(response.headers["Location"]).to be_present

      body = JSON.parse(response.body)
      expect(body["userName"]).to eq("new.hire@acme.com")
      expect(body["name"]["givenName"]).to eq("Alice")
      expect(body["name"]["familyName"]).to eq("Smith")
      expect(body["active"]).to be true

      log = Auth::AuditLog.recent.first
      expect(log.event_type).to eq("scim_user_created")
      expect(log.auth_method).to eq("scim")
      expect(log.account).to eq(account)
    end

    it "returns 409 Conflict if user is already an active member of this workspace" do
      duplicate_payload = {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        userName: "agent@acme.com",
        active: true
      }.to_json

      post "/api/scim/v2/users", params: duplicate_payload, headers: auth_headers

      expect(response).to have_http_status(:conflict)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("409")
      expect(body["scimType"]).to eq("uniqueness")
    end

    it "reactivates a previously deleted member" do
      member_account_user.update!(status: :deleted)

      reactivate_payload = {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        userName: "agent@acme.com",
        name: { givenName: "Jane Updated", familyName: "Doe" },
        active: true
      }.to_json

      expect {
        post "/api/scim/v2/users", params: reactivate_payload, headers: auth_headers
      }.not_to change(User, :count)

      expect(response).to have_http_status(:created)
      expect(member_account_user.reload.status).to eq("active")
      expect(member_user.reload.first_name).to eq("Jane Updated")
    end

    it "returns 400 Bad Request when email is missing" do
      invalid_payload = {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        name: { givenName: "NoEmail" }
      }.to_json

      post "/api/scim/v2/users", params: invalid_payload, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("400")
      expect(body["scimType"]).to eq("invalidValue")
    end
  end

  describe "PUT /api/scim/v2/users/:id" do
    let(:put_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        userName: "agent@acme.com",
        name: {
          givenName: "Janet",
          familyName: "Doe"
        },
        active: true
      }.to_json
    end

    it "updates the user details and returns the updated SCIM User representation" do
      put "/api/scim/v2/users/#{member_user.id}", params: put_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]["givenName"]).to eq("Janet")
      expect(member_user.reload.first_name).to eq("Janet")
    end
  end

  describe "PATCH /api/scim/v2/users/:id" do
    it "deactivates the user via Okta-style path replace operation" do
      patch_payload = {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          {
            op: "replace",
            path: "active",
            value: false
          }
        ]
      }.to_json

      patch "/api/scim/v2/users/#{member_user.id}", params: patch_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["active"]).to be false
      expect(member_account_user.reload.status).to eq("deleted")

      log = Auth::AuditLog.recent.first
      expect(log.event_type).to eq("scim_user_deactivated")
    end

    it "deactivates the user via Azure AD-style value hash replace operation" do
      azure_payload = {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          {
            op: "Replace",
            value: {
              active: false
            }
          }
        ]
      }.to_json

      patch "/api/scim/v2/users/#{member_user.id}", params: azure_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["active"]).to be false
      expect(member_account_user.reload.status).to eq("deleted")
    end

    it "updates user names via path replace operation" do
      patch_payload = {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          {
            op: "replace",
            path: "name.givenName",
            value: "Janelle"
          }
        ]
      }.to_json

      patch "/api/scim/v2/users/#{member_user.id}", params: patch_payload, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(member_user.reload.first_name).to eq("Janelle")
    end
  end

  describe "DELETE /api/scim/v2/users/:id" do
    it "deprovisions user by marking AccountUser deleted and returns 204 No Content" do
      delete "/api/scim/v2/users/#{member_user.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(member_account_user.reload.status).to eq("deleted")

      log = Auth::AuditLog.recent.first
      expect(log.event_type).to eq("scim_user_deactivated")
      expect(log.auth_method).to eq("scim")
      expect(log.account).to eq(account)
    end
  end
end
