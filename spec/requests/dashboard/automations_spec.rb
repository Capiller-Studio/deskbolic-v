# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Automations', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'automations' => true }, limits: { 'automations' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:automation) { create(:automation, account: account, name: 'Auto Assign') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /automations' do
    it 'renders automations index' do
      get automations_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /automations/new' do
    it 'renders new automation form' do
      get new_automation_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /automations' do
    it 'creates a new automation' do
      post automations_path(locale: :en), params: {
        automation: {
          name: 'Close inactive tickets',
          automation_type: 'time_trigger',
          event_name: 'ticket_created',
          status: 'active',
          conditions: {
            'operator' => 'AND',
            'groups' => [ {
              'operator' => 'AND',
              'conditions' => [ { 'attribute' => 'status', 'operator' => 'equals', 'value' => 'active' } ]
            } ]
          }.to_json,
          actions: [ { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } } ].to_json
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Automation.where(name: 'Close inactive tickets') }).to exist
    end
  end

  describe 'PATCH /automations/:id' do
    it 'updates automation' do
      patch automation_path(id: automation.id, locale: :en), params: {
        automation: { name: 'Auto Assign VIP' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { automation.reload.name }).to eq('Auto Assign VIP')
    end
  end

  describe 'DELETE /automations/:id' do
    it 'destroys automation' do
      delete automation_path(id: automation.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Automation.where(id: automation.id) }).not_to exist
    end
  end
end
