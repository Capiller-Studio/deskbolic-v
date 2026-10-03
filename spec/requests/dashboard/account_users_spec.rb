# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::AccountUsers', type: :request do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:teammate_user) { create(:user, confirmed_at: Time.current) }
  let!(:teammate_account_user) { create(:account_user, account: account, user: teammate_user, owner: false) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:agent_role) { account.roles.find_by(identifier: 'agent') || create(:access_role, account: account, identifier: 'agent', name: 'Agent') }
  let(:admin_role) { account.roles.find_by(identifier: 'administrator') || create(:access_role, account: account, identifier: 'administrator', name: 'Administrator') }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe 'GET /users' do
    it 'renders users index successfully' do
      get users_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /users/:id/edit' do
    it 'renders role edit page for teammate' do
      get edit_user_path(id: teammate_account_user.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end

    it 'renders role edit page for owner' do
      get edit_user_path(id: owner_account_user.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /users/:id' do
    it 'successfully assigns roles to a teammate in the shard' do
      patch user_path(id: teammate_account_user.id, locale: :en), params: {
        account_user: { role_ids: [agent_role.id] }
      }

      expect(response).to redirect_to(users_path)
      expect(flash[:notice]).to be_present
      expect(teammate_account_user.roles.reload).to include(agent_role)
    end

    it 'successfully updates owner roles while retaining the owner role' do
      patch user_path(id: owner_account_user.id, locale: :en), params: {
        account_user: { role_ids: [admin_role.id] }
      }

      expect(response).to redirect_to(users_path)
      expect(flash[:notice]).to be_present
      owner_roles = owner_account_user.roles.reload.map(&:identifier)
      expect(owner_roles).to include('owner')
      expect(owner_roles).to include('administrator')
    end
  end
end
