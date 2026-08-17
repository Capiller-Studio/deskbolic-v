# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Roles', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'roles' => true, 'custom_roles' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:custom_role) { create(:access_role, account: account, name: 'Custom Auditor', system_provided: false) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /roles' do
    it 'renders roles index' do
      get roles_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /roles/new' do
    it 'renders new role form' do
      get new_role_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /roles' do
    it 'creates a new custom role' do
      post roles_path(locale: :en), params: {
        access_role: { name: 'Support Lead', permissions: { 'conversations' => { 'read' => true } }.to_json }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Access::Role.where(name: 'Support Lead') }).to exist
    end
  end

  describe 'PATCH /roles/:id' do
    it 'updates role name' do
      patch role_path(id: custom_role.id, locale: :en), params: {
        access_role: { name: 'Auditor VIP', permissions: {}.to_json }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { custom_role.reload.name }).to eq('Auditor VIP')
    end
  end

  describe 'DELETE /roles/:id' do
    it 'destroys custom role' do
      delete role_path(id: custom_role.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Access::Role.where(id: custom_role.id) }).not_to exist
    end
  end
end
