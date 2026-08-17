# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Labels', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'labels' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:label) { create(:label, account: account, title: 'Bug') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /labels' do
    it 'renders labels index' do
      get labels_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /labels/new' do
    it 'renders new label form' do
      get new_label_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /labels' do
    it 'creates a new label' do
      post labels_path(locale: :en), params: {
        label: { title: 'Feature Request', color: '#10B981', description: 'Requested enhancements' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Label.where(title: 'Feature Request') }).to exist
    end
  end

  describe 'PATCH /labels/:id' do
    it 'updates label title' do
      patch label_path(id: label.id, locale: :en), params: {
        label: { title: 'Critical Bug' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { label.reload.title }).to eq('Critical Bug')
    end
  end

  describe 'DELETE /labels/:id' do
    it 'destroys label' do
      delete label_path(id: label.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Label.where(id: label.id) }).not_to exist
    end
  end
end
