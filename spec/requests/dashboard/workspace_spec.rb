# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Workspace', type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:account_one) { create(:account, name: 'Workspace Alpha') }
  let(:account_two) { create(:account, name: 'Workspace Beta') }
  let!(:account_user_one) { create(:account_user, account: account_one, user: user, owner: true) }
  let!(:account_user_two) { create(:account_user, account: account_two, user: user, owner: false) }

  before do
    sign_in user
  end

  describe 'GET /workspaces' do
    it 'renders the workspace chooser with all accessible accounts' do
      get workspaces_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Workspace Alpha')
      expect(response.body).to include('Workspace Beta')
    end
  end

  describe 'GET /workspace' do
    it 'renders new workspace form' do
      get workspace_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /workspace' do
    context 'when creating a new workspace' do
      it 'creates account and associates user as owner' do
        post workspace_path, params: {
          user_type: 'owner',
          account: { name: 'Acme Support' },
          company_name: 'Acme Inc',
          workspace_size: '10-50'
        }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
        created_account = user.reload.accounts.find_by(name: 'Acme Support')
        expect(created_account).to be_present
        expect(created_account.account_users.find_by(user: user)).to be_owner
        expect(response.redirect_url).to include(created_account.identifier)
      end
    end

    context 'when requesting to join existing workspace' do
      let!(:existing_account) { create(:account, email: "admin_#{SecureRandom.hex(4)}@targetcorp.com") }

      it 'sends workspace request email' do
        post workspace_path, params: {
          user_type: 'agent',
          email: existing_account.email
        }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      end
    end
  end
end
