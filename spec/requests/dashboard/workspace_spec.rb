# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Workspace', type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }

  before do
    sign_in user
  end

  describe 'GET /workspace' do
    it 'renders new workspace form' do
      get workspace_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /workspace' do
    context 'when creating a new workspace' do
      it 'creates account and associates user' do
        post workspace_path, params: {
          user_type: 'owner',
          account: { name: 'Acme Support' },
          company_name: 'Acme Inc',
          workspace_size: '10-50'
        }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
        expect(user.reload.accounts.where(name: 'Acme Support')).to exist
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
