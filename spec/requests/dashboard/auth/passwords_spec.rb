# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Passwords', type: :request do
  let(:user) { create(:user, email: 'forgot@example.com') }

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
end
