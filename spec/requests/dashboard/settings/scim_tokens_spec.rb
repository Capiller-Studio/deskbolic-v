# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard::Settings::ScimTokensController", type: :request do
  let(:plan) { create(:plan, features: { "sso" => true, "scim" => true }) }
  let(:account) { create(:account) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:owner_user) { create(:user, password: "password123", confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe "POST /settings/scim_tokens" do
    it "generates a new token and stores flash with raw token" do
      expect {
        post settings_scim_tokens_path(locale: :en), params: {
          auth_scim_token: { name: "Okta SCIM Integration" }
        }
      }.to change(Auth::ScimToken, :count).by(1)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:notice]).to be_present
      expect(flash[:new_scim_token]).to be_present

      token = Auth::ScimToken.last
      expect(token.name).to eq("Okta SCIM Integration")
      expect(token.account).to eq(account)
      expect(token.token_digest).to eq(Digest::SHA256.hexdigest(flash[:new_scim_token]))
    end
  end

  describe "DELETE /settings/scim_tokens/:id" do
    let!(:token) { create(:auth_scim_token, account: account, name: "Old Token") }

    it "revokes and destroys the SCIM token" do
      expect {
        delete settings_scim_token_path(id: token.id, locale: :en)
      }.to change(Auth::ScimToken, :count).by(-1)

      expect(response).to redirect_to(settings_sso_path)
      expect(flash[:notice]).to be_present
    end
  end
end
