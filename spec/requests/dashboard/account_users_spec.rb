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
        account_user: { role_ids: [ agent_role.id ] }
      }

      expect(response).to redirect_to(users_path)
      expect(flash[:notice]).to be_present
      expect(teammate_account_user.roles.reload).to include(agent_role)
    end

    it 'successfully updates owner roles while retaining the owner role' do
      patch user_path(id: owner_account_user.id, locale: :en), params: {
        account_user: { role_ids: [ admin_role.id ] }
      }

      expect(response).to redirect_to(users_path)
      expect(flash[:notice]).to be_present
      owner_roles = owner_account_user.roles.reload.map(&:identifier)
      expect(owner_roles).to include('owner')
      expect(owner_roles).to include('administrator')
    end
  end

  describe 'DELETE /users/:id' do
    let(:team) { account.with_shard { create(:team, account: account, name: 'Operations') } }
    let(:inbox) { account.with_shard { create(:inbox, account: account, name: 'Support Inbox') } }
    let!(:team_user) { account.with_shard { create(:team_user, team: team, user: teammate_user) } }
    let!(:inbox_user) { account.with_shard { create(:inbox_user, inbox: inbox, user: teammate_user) } }
    let!(:conversation) { account.with_shard { create(:conversation, account: account, inbox: inbox, assignee: teammate_user) } }

    it 'removes teammate and cleans up their team_users, inbox_users, and assigned conversations on the shard' do
      expect {
        delete user_path(id: teammate_account_user.id, locale: :en)
      }.to change { account.account_users.count }.by(-1)

      expect(response).to redirect_to(users_path)
      expect(flash[:notice]).to be_present

      account.with_shard do
        expect(TeamUser.exists?(team_id: team.id, user_id: teammate_user.id)).to be false
        expect(InboxUser.exists?(inbox_id: inbox.id, user_id: teammate_user.id)).to be false
        expect(conversation.reload.assignee_id).to be_nil
      end
    end

    it 'prevents removing the account owner' do
      delete user_path(id: owner_account_user.id, locale: :en)
      expect(response).to redirect_to(users_path)
      expect(flash[:alert]).to include('cannot remove the account owner')
      expect(owner_account_user.reload).to be_persisted
    end

    it 'prevents user from removing themselves' do
      sign_in teammate_user
      delete user_path(id: teammate_account_user.id, locale: :en)
      expect(response).to redirect_to(users_path)
      expect(flash[:alert]).to include('cannot remove yourself')
      expect(teammate_account_user.reload).to be_persisted
    end
  end
end
