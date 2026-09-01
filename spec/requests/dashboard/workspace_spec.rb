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

      it 'assigns the creator as owner with the Owner role' do
        post workspace_path, params: {
          user_type: 'owner',
          account: { name: 'Owner Role WS' },
          company_name: 'Acme Inc',
          workspace_size: '10-50'
        }

        account_user = user.reload.accounts.find_by(name: 'Owner Role WS')
                             &.account_users&.find_by(user: user)

        expect(account_user).to be_present
        expect(account_user.owner?).to be(true)
        expect(account_user.roles.map(&:identifier)).to include('owner')
      end

      it 'gives the creator full permissions so policies allow actions like channel creation' do
        post workspace_path, params: {
          user_type: 'owner',
          account: { name: 'Perm WS' },
          company_name: 'Acme Inc',
          workspace_size: '10-50'
        }

        account_user = user.reload.accounts.find_by(name: 'Perm WS')
                             &.account_users&.find_by(user: user)

        expect(account_user.can?('inboxes.read')).to be(true)
        expect(account_user.can?('inboxes.write')).to be(true)
      end

      it 'does not create the workspace when owner onboarding fails' do
        allow(AccountUser).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(AccountUser.new))

        expect do
          post workspace_path, params: {
            user_type: 'owner',
            account: { name: 'Rollback WS' },
            company_name: 'Acme Inc',
            workspace_size: '10-50'
          }
        end.not_to change(Account, :count)

        expect(user.reload.accounts.where(name: 'Rollback WS')).not_to exist
      end
    end

    context 'when requesting to join existing workspace' do
      let!(:existing_account) { create(:account, email: "admin_#{SecureRandom.hex(4)}@targetcorp.com") }

      it 'sends workspace request email' do
        allow(AdminNotificationMailer).to receive(:workspace_request).and_return(double(deliver_now: true))
        post workspace_path, params: {
          user_type: 'agent',
          email: existing_account.email
        }
        expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      end
    end
  end
end
