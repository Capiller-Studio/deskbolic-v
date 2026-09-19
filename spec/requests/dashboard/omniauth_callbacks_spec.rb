# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard::OmniauthCallbacks", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  describe "POST /users/auth/google_oauth2/callback" do
    let(:google_uid) { "google_123456789" }
    let(:email)      { "google.user@example.com" }

    before do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid:      google_uid,
        info: {
          email:      email,
          first_name: "Google",
          last_name:  "Tester",
          name:       "Google Tester"
        },
        credentials: {
          token: "mock_token_123"
        }
      )
    end

    it "provisions user and signs them in via unified identity resolver" do
      expect do
        post user_google_oauth2_omniauth_callback_path
      end.to change(User, :count).by(1)
         .and change(Auth::UserIdentity, :count).by(1)

      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)

      user = User.find_by(email: email)
      expect(user).to be_present
      expect(controller.current_user).to eq(user)

      identity = user.auth_identities.find_by(provider: :google, uid: google_uid)
      expect(identity).to be_present

      audit_log = Auth::AuditLog.recent.first
      expect(audit_log.event_type).to eq("login_success")
      expect(audit_log.auth_method).to eq("google")
    end
  end

  describe "POST /users/auth/facebook/callback" do
    let(:facebook_uid) { "fb_987654321" }
    let(:email)        { "fb.user@example.com" }

    before do
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
        provider: "facebook",
        uid:      facebook_uid,
        info: {
          email:      email,
          first_name: "Facebook",
          last_name:  "Tester",
          name:       "Facebook Tester"
        },
        credentials: {
          token: "mock_fb_token_123"
        }
      )
    end

    it "provisions user and signs them in" do
      expect do
        post user_facebook_omniauth_callback_path
      end.to change(User, :count).by(1)
         .and change(Auth::UserIdentity, :count).by(1)

      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)

      user = User.find_by(email: email)
      expect(user).to be_present
      expect(controller.current_user).to eq(user)

      identity = user.auth_identities.find_by(provider: :facebook, uid: facebook_uid)
      expect(identity).to be_present

      audit_log = Auth::AuditLog.recent.first
      expect(audit_log.event_type).to eq("login_success")
      expect(audit_log.auth_method).to eq("facebook")
    end
  end
end
