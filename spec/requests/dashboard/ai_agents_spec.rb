# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::AiAgents', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'ai_agents' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:ai_agent) { create(:ai_agent, account: account, name: 'Support Bot') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /ai_agents' do
    it 'renders ai agents index' do
      get ai_agents_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /ai_agents/new' do
    it 'renders new ai agent form' do
      get new_ai_agent_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /ai_agents' do
    it 'creates new ai agent' do
      post ai_agents_path(locale: :en), params: {
        ai_agent: {
          name: 'HelpBot',
          agent_type: 'help_center_bot',
          tone: 'friendly',
          status: 'active',
          confidence_threshold: 0.8,
          max_exchanges: 5
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Ai::Agent.where(name: 'HelpBot') }).to exist
    end
  end

  describe 'PATCH /ai_agents/:id' do
    it 'updates ai agent' do
      patch ai_agent_path(id: ai_agent.id, locale: :en), params: {
        ai_agent: { name: 'Support Bot Pro' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { ai_agent.reload.name }).to eq('Support Bot Pro')
    end
  end

  describe 'DELETE /ai_agents/:id' do
    it 'destroys ai agent' do
      delete ai_agent_path(id: ai_agent.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Ai::Agent.where(id: ai_agent.id) }).not_to exist
    end
  end
end
