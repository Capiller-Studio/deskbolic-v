# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Affiliate Referral Tracking & Commission End-to-End Browser Flow', :js, type: :feature do
  let(:affiliate_user) { create(:user, confirmed_at: Time.current, display_name: 'Affiliate Partner') }
  let(:affiliate_profile) do
    create(:affiliate_profile,
      user: affiliate_user,
      referral_code: 'TOP-PARTNER-77',
      commission_rate: 20.0,
      holding_days: 0,
      currency: 'USD'
    )
  end

  let(:plan) do
    create(:plan,
      name: 'Pro Tier',
      features: { 'automations' => true, 'roles' => true },
      limits: { 'users' => 10, 'automations' => 10 }
    )
  end

  around do |example|
    orig = ENV.fetch('DISABLE_REGISTRATION', nil)
    ENV['DISABLE_REGISTRATION'] = 'false'
    example.run
    ENV['DISABLE_REGISTRATION'] = orig
  end

  describe 'Visitor Referral Attribution and Registration Journey' do
    let(:unique_id) { SecureRandom.hex(4) }
    let(:visitor_email) { "referred.founder.#{unique_id}@startup.example.com" }
    let(:company_name) { "Nova Dynamics #{unique_id}" }
    let(:company_slug) { "nova-dyn-#{unique_id}" }

    it 'captures referral code from query params, sets cookie, links referral record, and calculates commission' do
      affiliate_profile # Ensure profile is created

      # 1. Visitor clicks affiliate link with ?ref=TOP-PARTNER-77
      visit new_user_registration_path(locale: :en, ref: affiliate_profile.referral_code)
      expect(page).to have_current_path(%r{/(en/)?register})

      # Verify hidden referral input received referral code
      ref_input = find('input#ref', visible: false)
      expect(ref_input.value).to eq('TOP-PARTNER-77')

      # 2. Fill in Step 1: User Credentials
      fill_in 'user[first_name]', with: 'Eleanor'
      fill_in 'user[last_name]', with: 'Vance'
      page.execute_script("const el = document.getElementById('country'); if (el) { el.value = 'US'; el.dispatchEvent(new Event('change', { bubbles: true })); }")
      fill_in 'user[email]', with: visitor_email
      fill_in 'user[password]', with: 'SecureP@ssw0rd2026!'
      fill_in 'user[password_confirmation]', with: 'SecureP@ssw0rd2026!'

      # 3. Advance to Step 2: Account / Workspace Configuration
      find('button[data-action="click->registration-wizard#nextStep"]').click
      expect(page).to have_text(I18n.t('auth.registration.step2_title'))

      fill_in 'account_name', with: company_name
      fill_in 'account_identifier', with: company_slug
      choose('shard_key_de', allow_label_click: true)

      # 4. Submit Registration
      find('input[type="submit"]').click

      # Expect successful registration screen
      expect(page).to have_text(I18n.t('devise.registrations.registered_title', default: 'Check your email')).or have_text('registered')

      # 5. Verify Backend Referral Association Created by Affiliates::Referrals::Tracker
      new_account = Account.find_by(identifier: company_slug)
      expect(new_account).to be_present

      referral = Affiliate::Referral.find_by(account: new_account)
      expect(referral).to be_present
      expect(referral.profile).to eq(affiliate_profile)
      expect(referral).to be_active

      # 6. Customer purchases a plan and transaction charges
      transaction = create(:transaction,
        account: new_account,
        transaction_type: :charge,
        status: :completed,
        amount: 100.00,
        currency: 'USD'
      )

      # Trigger Commission Calculation
      Affiliates::Commissions::Calculator.call(transaction: transaction)

      # 7. Verify Commission Generated
      commission = Affiliate::Commission.find_by(transaction_record_id: transaction.id)
      expect(commission).to be_present
      expect(commission.profile).to eq(affiliate_profile)
      expect(commission.referral).to eq(referral)
      expect(commission.amount).to eq(20.00) # 20% of 100.00
      expect(commission.currency).to eq('USD')
      expect(commission.status).to eq('available') # holding_days is 0
    end
  end
end
