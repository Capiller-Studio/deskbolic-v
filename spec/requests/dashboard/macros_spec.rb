# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Macros', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:macro) { create(:macro, account: account, name: 'Close & Resolve', visibility: :account_wide) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /macros' do
    it 'renders macros index' do
      get macros_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /macros/new' do
    it 'renders new macro form' do
      get new_macro_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /macros' do
    it 'creates a new macro' do
      post macros_path(locale: :en), params: {
        macro: {
          name: 'Escalate to Tier 2',
          visibility: 'account_wide',
          actions: [ { 'type' => 'set_priority', 'value' => 'urgent' } ]
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Macro.where(name: 'Escalate to Tier 2') }).to exist
    end
  end

  describe 'PATCH /macros/:id' do
    it 'updates macro' do
      patch macro_path(id: macro.id, locale: :en), params: {
        macro: { name: 'Close & Archive' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { macro.reload.name }).to eq('Close & Archive')
    end
  end

  describe 'DELETE /macros/:id' do
    it 'destroys macro' do
      delete macro_path(id: macro.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Macro.where(id: macro.id) }).not_to exist
    end
  end
end
