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
    context 'when user has a single account' do
      it 'authenticates user and redirects to account subdomain' do
        post user_session_path, params: { user: { email: user.email, password: 'password123' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
        expect(response.redirect_url).to include(account.identifier)
      end
    end

    context 'when user has multiple accounts' do
      let(:account_two) { create(:account) }
      let!(:account_user_two) { create(:account_user, account: account_two, user: user) }

      it 'authenticates user on apex domain and redirects to workspaces chooser' do
        post user_session_path, params: { user: { email: user.email, password: 'password123' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
        expect(response.redirect_url).to include('/workspaces')
      end

      it 'authenticates user on specific account subdomain and redirects directly to that workspace' do
        set_subdomain(account_two.identifier)
        post user_session_path, params: { user: { email: user.email, password: 'password123' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
        expect(response.redirect_url).to include(account_two.identifier)
      end
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
