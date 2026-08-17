# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::HelpCenter::Portals', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'help_center_portals' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:domain) { create(:domain, account: account) }
  let(:portal) { create(:help_center_portal, account: account, domain: domain, name: 'Main Help Center') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /help_center/portals' do
    it 'renders help center portals index' do
      get help_center_portals_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /help_center/portals/new' do
    it 'renders new portal form' do
      get new_help_center_portal_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /help_center/portals' do
    it 'creates a new help center portal with subdomain' do
      post help_center_portals_path(locale: :en), params: {
        help_center_portal: {
          name: 'Knowledge Base',
          domain_type: 'subdomain',
          subdomain_slug: "help-#{SecureRandom.hex(3)}",
          default_locale: 'en',
          locales: [ 'en' ],
          ai_training_enabled: true
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { HelpCenter::Portal.where(name: 'Knowledge Base') }).to exist
    end
  end

  describe 'PATCH /help_center/portals/:id' do
    it 'updates portal name' do
      patch help_center_portal_path(id: portal.id, locale: :en), params: {
        help_center_portal: { name: 'Updated Docs Hub' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { portal.reload.name }).to eq('Updated Docs Hub')
    end
  end
end
