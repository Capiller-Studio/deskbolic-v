# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subscription Selection Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, name: Plan::ANABOLIC, currency: account.currency, status: :active, trial_days: 14, limits: { 'users_min' => 2, 'users_max' => 10 }) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'allows viewing plans and selecting seats before subscribing' do
    visit new_subscription_path(locale: :en)

    expect(page).to have_text(plan.display_name)
    expect(page).to have_text('Seats')
    expect(page).to have_field("seats_#{plan.id}", with: '2')

    fill_in "seats_#{plan.id}", with: '4'
    click_button I18n.t('dashboard.billing.subscription_page.start_free_trial')

    expect(page).to have_current_path(root_path)
    expect(page).to have_text(I18n.t('dashboard.billing.subscription_created', default: 'Subscription successfully created!'))

    sub = Subscription.last
    expect(sub.quantity).to eq(4)
    expect(sub.plan).to eq(plan)
  end
end
