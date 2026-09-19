# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SSO Authentication Feature', type: :feature do
  let(:password) { 'SecurePass123!' }
  let(:account) { create(:account, name: 'Acme Enterprise', status: :active) }
  let(:parabolic_plan) { create(:plan, name: Plan::PARABOLIC, features: { 'sso' => true }) }
  let!(:subscription) { create(:subscription, account: account, plan: parabolic_plan, status: :active) }

  let!(:sso_config) do
    create(:auth_sso_configuration,
      account: account,
      status: :active,
      enforce_sso: true,
      allowed_email_domains: [ 'corp.acme.com' ],
      allow_owner_password_fallback: true
    )
  end

  let!(:domain_verification) do
    create(:auth_domain_verification,
      account: account,
      domain: 'corp.acme.com',
      status: :verified,
      verified_at: Time.current
    )
  end

  let(:owner_user) do
    create(:user,
      email: 'owner@corp.acme.com',
      password: password,
      password_confirmation: password,
      confirmed_at: Time.current
    )
  end
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  let(:employee_user) do
    create(:user,
      email: 'employee@corp.acme.com',
      password: password,
      password_confirmation: password,
      confirmed_at: Time.current
    )
  end
  let!(:employee_account_user) { create(:account_user, account: account, user: employee_user, owner: false) }

  before do
    # Clear Redis domain cache before each test
    Auth::DomainLookupService.clear_cache('corp.acme.com')
  end

  describe 'password authentication blocking when SSO is enforced' do
    it 'blocks password login on enforced domain and renders SSO banner with prefilled email' do
      visit new_user_session_path(locale: :en)

      expect(page).to have_text('Single Sign-On (SSO)')

      fill_in 'user[email]', with: 'employee@corp.acme.com'
      fill_in 'user[password]', with: password
      click_button 'Sign in'

      # Redirected with enforced notice
      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_text('Single Sign-On is required for Acme Enterprise. Please sign in with SSO.')
      expect(page).to have_field('user[email]', with: 'employee@corp.acme.com')
      expect(page).to have_link('Sign in with SSO')

      # Audit log recorded
      log = Auth::AuditLog.last
      expect(log.event_type).to eq('login_failure')
      expect(log.error_code).to eq('sso_enforced')
      expect(log.email).to eq('employee@corp.acme.com')
    end
  end

  describe 'emergency break-glass password bypass' do
    it 'allows the workspace owner to sign in with password using bypass_sso=true' do
      visit new_user_session_path(locale: :en, bypass_sso: 'true')

      fill_in 'user[email]', with: 'owner@corp.acme.com'
      fill_in 'user[password]', with: password
      click_button 'Sign in'

      expect(page).to have_no_text('Single Sign-On is required')
      expect(page).to have_current_path(%r{/(en/)?(workspaces|channels)?})

      # Audit log recorded
      log = Auth::AuditLog.where(event_type: 'bypass_login').last
      expect(log).not_to be_nil
      expect(log.user_id).to eq(owner_user.id)
      expect(log.status).to eq('success')
    end

    it 'denies break-glass bypass to non-owner users and records audit log' do
      visit new_user_session_path(locale: :en, bypass_sso: 'true')

      fill_in 'user[email]', with: 'employee@corp.acme.com'
      fill_in 'user[password]', with: password
      click_button 'Sign in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_text('Emergency password bypass is restricted to Account Owners.')

      # Audit log recorded
      log = Auth::AuditLog.where(error_code: 'bypass_denied').last
      expect(log).not_to be_nil
      expect(log.email).to eq('employee@corp.acme.com')
      expect(log.status).to eq('failure')
    end
  end
end
