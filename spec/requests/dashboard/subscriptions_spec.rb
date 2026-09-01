# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Subscriptions', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, :free, status: :active, currency: account.currency) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /subscriptions/new' do
    it 'renders plan selection page' do
      get new_subscription_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.display_name)
    end
  end

  describe 'POST /subscriptions' do
    it 'creates the subscription and redirects to the dashboard root' do
      expect do
        post subscriptions_path(locale: :en), params: { plan_id: plan.id, billing_cycle: 'monthly', quantity: 1 }
      end.to change { account.subscriptions.count }.by(1)

      expect(response).to redirect_to(root_path)
    end

    it 'lands on the dashboard when following the redirect chain' do
      post subscriptions_path(locale: :en), params: { plan_id: plan.id, billing_cycle: 'monthly', quantity: 1 }
      5.times { follow_redirect! if response.redirect? }

      expect(response).to have_http_status(:ok)
    end
  end
end
