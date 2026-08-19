# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Sessions', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'agent@example.com', password: 'password123', password_confirmation: 'password123', confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user) }

  describe 'GET /users/sign_in' do
    it 'renders sign in page' do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users/sign_in' do
    it 'authenticates user and redirects' do
      post user_session_path, params: { user: { email: user.email, password: 'password123' } }
      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      expect(response.redirect_url).to include(account.identifier)
    end

    it 'fails authentication with invalid password' do
      post user_session_path, params: { user: { email: user.email, password: 'WrongPassword!' } }
      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:ok)
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'signs out user' do
      sign_in user
      delete destroy_user_session_path
      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
    end
  end
end
