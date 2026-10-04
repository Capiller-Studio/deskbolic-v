# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::SlaPolicies', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'sla' => true, 'roles' => true },
      limits: { 'sla_policies' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let(:sla_policy) { account.with_shard { create(:sla_policy, account: account, name: 'VIP 15m Response') } }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /sla_policies' do
    it 'renders the SLA policies index' do
      sla_policy
      get sla_policies_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('VIP 15m Response')
    end

    it 'supports i18n locales' do
      get sla_policies_path(locale: :de)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /sla_policies/new' do
    it 'renders the new policy form' do
      get new_sla_policy_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('sla_policy[name]')
    end
  end

  describe 'POST /sla_policies' do
    it 'creates an SLA policy and syncs associated inboxes' do
      expect {
        post sla_policies_path(locale: :en), params: {
          sla_policy: {
            name: 'Standard Priority SLA',
            description: 'Handles general support queries',
            during_working_hours: '1',
            initial_response_value: '30',
            initial_response_unit: 'minutes',
            resolution_value: '4',
            resolution_unit: 'hours',
            inbox_ids: [ inbox.id ]
          }
        }
      }.to change { account.with_shard { SlaPolicy.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(sla_policies_path)
      created = account.with_shard { SlaPolicy.where(account_id: account.id).find_by(name: 'Standard Priority SLA') }
      expect(created.initial_response_time_limit).to eq(1800.0) # 30 minutes in seconds
      expect(created.resolution_time_limit).to eq(14400.0) # 4 hours in seconds
      expect(account.with_shard { created.inboxes }).to include(inbox)
    end

    it 'renders new on validation error' do
      post sla_policies_path(locale: :en), params: {
        sla_policy: { name: '' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /sla_policies/:id/edit' do
    it 'renders the edit policy form' do
      get edit_sla_policy_path(id: sla_policy.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('VIP 15m Response')
    end
  end

  describe 'PATCH /sla_policies/:id' do
    it 'updates policy name and response times' do
      patch sla_policy_path(id: sla_policy.id, locale: :en), params: {
        sla_policy: {
          name: 'Updated Enterprise SLA',
          initial_response_value: '10',
          initial_response_unit: 'minutes'
        }
      }
      expect(response).to redirect_to(sla_policies_path)
      account.with_shard do
        sla_policy.reload
        expect(sla_policy.name).to eq('Updated Enterprise SLA')
        expect(sla_policy.initial_response_time_limit).to eq(600.0)
      end
    end
  end

  describe 'DELETE /sla_policies/:id' do
    it 'destroys the SLA policy' do
      policy_id = sla_policy.id
      expect {
        delete sla_policy_path(id: policy_id, locale: :en)
      }.to change { account.with_shard { SlaPolicy.where(account_id: account.id).count } }.by(-1)

      expect(response).to redirect_to(sla_policies_path)
    end
  end
end
