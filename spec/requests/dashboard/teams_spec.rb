# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Teams', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:team) { create(:team, account: account, name: 'Billing Support') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /teams' do
    it 'renders teams index' do
      get teams_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /teams' do
    it 'creates a new team' do
      post teams_path(locale: :en), params: {
        team: { name: 'Escalations Team', description: 'Handles tier 2 issues' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Team.where(name: 'Escalations Team') }).to exist
    end
  end

  describe 'PATCH /teams/:id' do
    it 'updates team details' do
      patch team_path(id: team.id, locale: :en), params: {
        team: { name: 'Tier 1 Support' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { team.reload.name }).to eq('Tier 1 Support')
    end
  end

  describe 'DELETE /teams/:id' do
    it 'destroys team' do
      delete team_path(id: team.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Team.where(id: team.id) }).not_to exist
    end
  end
end
