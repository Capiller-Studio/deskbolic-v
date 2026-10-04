# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Passwords', type: :request do
  let(:user) { create(:user, email: 'forgot@example.com', confirmed_at: Time.current) }

  describe 'GET /users/password/new' do
    it 'renders password recovery page' do
      get new_user_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users/password' do
    it 'sends reset password instructions' do
      post user_password_path, params: { user: { email: user.email } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET /users/password/edit' do
    let(:raw_token) do
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)
      raw
    end

    it 'renders password edit form when not signed in' do
      get edit_user_password_path(reset_password_token: raw_token)
      expect(response).to have_http_status(:ok)
    end

    it 'renders password edit form without redirecting to login when already signed in' do
      sign_in user
      get edit_user_password_path(reset_password_token: raw_token)
      expect(response).to have_http_status(:ok)
      expect(controller.user_signed_in?).to be(false)
    end
  end

  describe 'PUT /users/password' do
    let(:raw_token) do
      raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)
      raw
    end

    it 'allows resetting password even when a prior session was active' do
      other_user = create(:user, email: 'other@example.com', confirmed_at: Time.current)
      sign_in other_user

      put user_password_path, params: {
        user: {
          reset_password_token: raw_token,
          password: 'NewStrongPassword123!',
          password_confirmation: 'NewStrongPassword123!'
        }
      }

      expect(response).to have_http_status(:redirect)
      expect(user.reload.valid_password?('NewStrongPassword123!')).to be(true)
    end
  end
end
