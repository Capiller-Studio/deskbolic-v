# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Billing Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :momentum) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:wallet) { create(:wallet, account: account, balance: 1000.0) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'displays active subscription and wallet balance' do
    visit dashboard_billing_path(locale: :en)

    expect(page).to have_text(I18n.t('dashboard.billing.title'))
    expect(page).to have_text(I18n.t('dashboard.billing.active_subscription'))
    expect(page).to have_text(plan.display_name)

    # Verify wallet balance
    expect(page).to have_text(I18n.t('dashboard.billing.wallet'))
    expect(page).to have_text('1,000.00')
  end
end
