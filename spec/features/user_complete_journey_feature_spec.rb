# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Complete End-to-End Journey Feature', :js, type: :feature do
  let!(:country) { Country.find_or_create_by!(iso: 'US') { |c| c.iso_name = 'United States'; c.iso3 = 'USA' } }
  let!(:plan) do
    create(:plan,
      features: { 'roles' => true, 'channels' => { 'custom' => true } },
      limits: { 'channels' => 10, 'users' => 10 }
    )
  end

  around do |example|
    orig = ENV.fetch('DISABLE_REGISTRATION', nil)
    ENV['DISABLE_REGISTRATION'] = 'false'
    example.run
    ENV['DISABLE_REGISTRATION'] = orig
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return([ '93.184.216.34' ])
  end

  it 'completes full user lifecycle: invalid signup, valid signup, confirmation, login, reset password, second workspace, and channel creation' do
    reset_subdomain

    # ---------------------------------------------------------
    # 1. Sign Up Attempt with Mismatched Passwords
    # ---------------------------------------------------------
    visit new_user_registration_path(locale: :en)
    expect(page).to have_text(I18n.t('auth.registration.step1_title'))

    fill_in 'user[first_name]', with: 'Alexander'
    fill_in 'user[last_name]', with: 'Hamilton'
    page.execute_script("const el = document.getElementById('country'); if (el) { el.value = 'US'; el.dispatchEvent(new Event('change', { bubbles: true })); }")
    fill_in 'user[email]', with: 'alexander.journey@example.com'

    # Enter mismatched passwords
    fill_in 'user[password]', with: 'FoundingFather2026!'
    fill_in 'user[password_confirmation]', with: 'MismatchPass123!'
    expect(page).to have_text(I18n.t('auth.password_mismatch', default: 'Passwords do not match'))

    # Correct password confirmation so they match
    fill_in 'user[password_confirmation]', with: 'FoundingFather2026!'
    expect(page).to have_text(I18n.t('auth.password_match', default: 'Passwords match'))

    # ---------------------------------------------------------
    # 2. Advance to Step 2 and Complete Registration
    # ---------------------------------------------------------
    find('button[data-action="click->registration-wizard#nextStep"]').click
    expect(page).to have_text(I18n.t('auth.registration.step2_title'))

    fill_in 'account_name', with: 'Treasury Department'
    fill_in 'account_identifier', with: 'treasury-hq'
    choose('shard_key_de', allow_label_click: true)

    find('input[type="submit"]').click

    # Registration succeeds
    expect(page).to have_text(I18n.t('devise.registrations.registered_title', default: 'Check your email')).or have_text('registered')

    user = User.find_by(email: 'alexander.journey@example.com')
    expect(user).to be_present
    account1 = Account.find_by(identifier: 'treasury-hq')
    expect(account1).to be_present
    expect(account1.name).to eq('Treasury Department')
    expect(user.confirmed?).to be false
    account1.subscriptions.first_or_create!(plan: plan, status: :active)

    # ---------------------------------------------------------
    # 3. Account Confirmation
    # ---------------------------------------------------------
    confirmation_token = user.confirmation_token
    visit user_confirmation_path(confirmation_token: confirmation_token, locale: :en)
    expect(user.reload.confirmed?).to be true

    # ---------------------------------------------------------
    # 4. Sign In with valid credentials
    # ---------------------------------------------------------
    reset_subdomain
    visit new_user_session_path(locale: :en)
    find('input[type="email"]').set('alexander.journey@example.com')
    find('input[type="password"]').set('FoundingFather2026!')
    click_button I18n.t('auth.login.submit', default: 'Sign In')

    # Single workspace redirects directly to the tenant subdomain
    expect(page).to have_current_path(%r{/(?:conversations|channels)?\z})
    host_for_account(account1)

    # ---------------------------------------------------------
    # 5. Create a Second Workspace & View Account Chooser
    # ---------------------------------------------------------
    reset_subdomain
    visit "#{Capybara.app_host}/en/workspace"

    fill_in 'account[name]', with: 'Federal Reserve Bank'
    click_button I18n.t('dashboard.workspace.new.create_workspace_button')
    expect(page).to have_text(/New workspace created successfully|Choose your perfect plan|Starter Plan/i)

    account2 = Account.find_by!(name: 'Federal Reserve Bank')
    account2.subscriptions.first_or_create!(plan: plan, status: :active)
    expect(account2.account_users.find_by(user: user)).to be_owner

    # Visiting workspaces on apex domain displays workspace chooser
    reset_subdomain
    visit "#{Capybara.app_host}/en/workspaces"
    expect(page).to have_text('Treasury Department')
    expect(page).to have_text('Federal Reserve Bank')

    # ---------------------------------------------------------
    # 6. Create a Test Custom Channel in Workspace 1
    # ---------------------------------------------------------
    host_for_account(account1)

    visit "#{Capybara.app_host}#{new_channels_custom_path(locale: :en)}"
    expect(page).to have_text(I18n.t('dashboard.custom_channels.new.title', default: 'Add New Custom Channel')).or have_field('channel_custom[name]')

    fill_in 'channel_custom[name]', with: 'Automated Hook System'
    fill_in 'channel_custom[webhook_url]', with: 'https://example.com/system_webhooks'
    find('button[form="custom-channel-form"]').click

    expect(page).to have_text('Automated Hook System')

    channel = account1.with_shard { Channel::Custom.find_by(name: 'Automated Hook System') }
    expect(channel).to be_present
    expect(channel.webhook_secret).to be_present
    expect(channel.hmac_token).to be_present

    # ---------------------------------------------------------
    # 7. Password Reset Journey
    # ---------------------------------------------------------
    reset_subdomain
    page.driver.browser.manage.delete_all_cookies
    visit "#{Capybara.app_host}/en/password/new"
    find('input[type="email"]').set('alexander.journey@example.com')
    click_button I18n.t('auth.passwords.send_instructions')
    expect(page).to have_current_path(/login/)
  end
end
