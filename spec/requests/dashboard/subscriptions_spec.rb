# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Subscriptions', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, currency: account.currency, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /subscriptions/new' do
    context 'when account has no active subscription' do
      it 'renders plan selection successfully with feature highlights and seat selector' do
        get new_subscription_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(plan.display_name)
        expect(response.body).to include('100 free AI credits/mo')
        expect(response.body).to include("seats_#{plan.id}")
        expect(response.body).to include('Seats')
      end
    end

    context 'when account already has an active subscription' do
      before do
        create(:subscription, account: account, plan: plan, status: :active)
      end

      it 'redirects to root path' do
        get new_subscription_path(locale: :en)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /subscriptions' do
    it 'creates a subscription and redirects to root_path with 303 see_other' do
      expect {
        post subscriptions_path(locale: :en), params: {
          plan_id: plan.id,
          billing_cycle: 'monthly',
          quantity: 1
        }
      }.to change(Subscription, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(I18n.t('dashboard.billing.subscription_created', default: 'Subscription successfully created!'))
    end

    it 'creates a subscription with custom selected seats quantity' do
      multi_seat_plan = create(:plan, name: 'hyperbolic', currency: account.currency, status: :active, limits: { 'users_min' => 2, 'users_max' => 10 })

      expect {
        post subscriptions_path(locale: :en), params: {
          plan_id: multi_seat_plan.id,
          billing_cycle: 'monthly',
          quantity: 5
        }
      }.to change(Subscription, :count).by(1)

      sub = Subscription.last
      expect(sub.quantity).to eq(5)
      expect(sub.plan).to eq(multi_seat_plan)
    end
  end
end
