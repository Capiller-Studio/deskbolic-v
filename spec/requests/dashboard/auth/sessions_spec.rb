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

  describe 'POST /sessions/switch/:id' do
    let(:other_account) { create(:account, name: 'Workspace B') }
    let!(:other_account_user) { create(:account_user, account: other_account, user: user, owner: true) }
    let(:plan) do
      create(:plan, features: { 'channels' => { 'email' => true } }, limits: { 'channels' => 100, 'users' => 100 })
    end
    let!(:subscription) { create(:subscription, account: other_account, plan: plan, status: :active) }

    it 'stores the switched workspace in the session and redirects' do
      sign_in user
      post switch_account_path(id: other_account.id)

      expect(response).to redirect_to(root_url)
      expect(session[:current_account_id]).to eq(other_account.id)
    end

    it 'does not switch to a workspace the user does not belong to' do
      foreign_account = create(:account, name: 'Workspace C')

      sign_in user
      post switch_account_path(id: foreign_account.id)

      expect(response).to redirect_to(root_url)
      expect(session[:current_account_id]).not_to eq(foreign_account.id)
    end

    it 'renders the switched workspace data on the next request' do
      set_subdomain(account.identifier)
      sign_in user
      post switch_account_path(id: other_account.id)

      get root_path
      5.times { follow_redirect! if response.redirect? }

      expect(response).to have_http_status(:ok)
      expect(session[:current_account_id]).to eq(other_account.id)
      expect(response.body.index(other_account.name)).to be < response.body.index(account.name)
    end

    it 'sends stale URLs from the previous workspace to the dashboard instead of raising' do
      conversation = account.with_shard { create(:conversation, account: account) }

      set_subdomain(account.identifier)
      sign_in user
      post switch_account_path(id: other_account.id)

      # Simulates refreshing the old conversation URL after switching workspaces
      get conversation_path(conversation)

      expect(response).to redirect_to(root_path)
      5.times { follow_redirect! if response.redirect? }
      expect(response).to have_http_status(:ok)
    end

    it 'falls back to the oldest workspace when no selection is stored' do
      sign_in user
      get root_path

      expect(response).to redirect_to(root_url(subdomain: account.identifier))
    end
  end
end
