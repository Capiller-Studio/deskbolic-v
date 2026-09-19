# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SSO Settings Feature', type: :feature do
  let(:account) { create(:account, name: 'Acme Enterprise', status: :active) }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:parabolic_plan) { create(:plan, name: Plan::PARABOLIC, features: { 'sso' => true, 'scim' => true }) }
  let!(:subscription) { create(:subscription, account: account, plan: parabolic_plan, status: :active) }

  before do
    host_for_account(account)
    login_as(owner_user, scope: :user)
  end

  describe 'visiting SSO settings' do
    it 'displays the SSO configuration page with SP metadata' do
      visit settings_sso_path(locale: :en)

      expect(page).to have_text('Single Sign-On (SSO) & Directory Sync')
      expect(page).to have_text('Deskbolic Service Provider (SP) Metadata')
      expect(page).to have_text('Identity Provider (IdP) Configuration')
      expect(page).to have_text('Domain Ownership Verification (DNS TXT)')
      expect(page).to have_text('SCIM 2.0 Directory Synchronization')
      expect(page).to have_text('Recent Authentication Audit Logs')

      # Check SP ACS URL and Entity ID fields
      expect(page).to have_field(with: %r{/auth/saml/consume})
      expect(page).to have_field(with: %r{/auth/saml/metadata})
    end

    it 'allows configuring SAML settings' do
      visit settings_sso_path(locale: :en)

      select 'SAML 2.0 (Recommended)', from: 'auth_sso_configuration[protocol]'
      select 'Okta', from: 'auth_sso_configuration[provider_type]'
      select 'Active (Production)', from: 'auth_sso_configuration[status]'

      fill_in 'auth_sso_configuration[idp_entity_id]', with: 'http://www.okta.com/exk123456789'
      fill_in 'auth_sso_configuration[idp_sso_url]', with: 'https://example.okta.com/app/sso/saml'
      fill_in 'auth_sso_configuration[idp_certificate_raw]', with: AuthTestCertificateHelper.generate_pem
      fill_in 'auth_sso_configuration[allowed_email_domains_raw]', with: 'acme.corp, global.acme.corp'
      fill_in 'auth_sso_configuration[session_timeout_hours]', with: '24'

      check 'auth_sso_configuration[enforce_sso]'
      check 'auth_sso_configuration[jit_provisioning_enabled]'
      check 'auth_sso_configuration[allow_owner_password_fallback]'

      click_button 'Save Changes'

      expect(page).to have_text('Single Sign-On settings updated successfully.')

      config = account.reload.sso_configuration
      expect(config).to be_present
      expect(config.protocol).to eq('saml')
      expect(config.provider_type).to eq('okta')
      expect(config.status).to eq('active')
      expect(config.idp_entity_id).to eq('http://www.okta.com/exk123456789')
      expect(config.idp_sso_url).to eq('https://example.okta.com/app/sso/saml')
      expect(config.allowed_email_domains).to contain_exactly('acme.corp', 'global.acme.corp')
      expect(config.session_timeout_hours).to eq(24)
      expect(config.enforce_sso).to be true
      expect(config.jit_provisioning_enabled).to be true
      expect(config.allow_owner_password_fallback).to be true
    end
  end

  describe 'domain verification workflow' do
    it 'allows adding and verifying corporate domains' do
      visit settings_sso_path(locale: :en)

      fill_in 'auth_domain_verification[domain]', with: 'corp.acme.com'
      click_button 'Add Domain'

      expect(page).to have_text('Domain added. Please configure DNS TXT record to verify ownership.')
      expect(page).to have_text('corp.acme.com')
      expect(page).to have_field(with: %r{deskbolic-verify=})

      # Mock DNS verification
      verification = account.domain_verifications.find_by(domain: 'corp.acme.com')
      expect(verification).not_to be_nil
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Auth::DnsVerifier).to receive(:query_txt_records).and_return([ verification.dns_txt_expected_value ])
      # rubocop:enable RSpec/AnyInstance

      click_button 'Verify Now'

      expect(page).to have_text("Domain 'corp.acme.com' verified successfully! It is now active for SSO.")
      expect(verification.reload.verified?).to be true

      # Remove domain
      find('button[aria-label="Delete"]').click
      expect(page).to have_text('Domain removed successfully.')
      expect(account.domain_verifications.where(domain: 'corp.acme.com')).not_to exist
    end
  end

  describe 'SCIM token management' do
    it 'allows generating and revoking SCIM directory sync tokens' do
      visit settings_sso_path(locale: :en)

      click_button 'Generate SCIM Token'

      expect(page).to have_text('SCIM API Token Generated Successfully')
      expect(page).to have_text('Copy your bearer token now')
      expect(account.scim_tokens.count).to eq(1)

      token = account.scim_tokens.first
      expect(page).to have_text(token.name)

      # Revoke token
      find('button[aria-label="Revoke"]').click
      expect(page).to have_text('SCIM Token revoked.')
      expect(account.scim_tokens.count).to eq(0)
    end
  end

  describe 'plan gating' do
    let(:symbolic_plan) { create(:plan, name: Plan::SYMBOLIC, features: { 'sso' => false, 'scim' => false }) }

    before do
      subscription.update!(plan: symbolic_plan)
    end

    it 'redirects workspaces without SSO feature to general settings' do
      visit settings_sso_path(locale: :en)

      expect(page).to have_current_path(%r{/(en/)?settings/general})
      expect(page).to have_text('Enterprise SSO is available on the Parabolic plan.')
    end
  end

  describe 'role authorization' do
    let(:agent_user) { create(:user, confirmed_at: Time.current) }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

    before do
      login_as(agent_user, scope: :user)
    end

    it 'denies access to regular agents lacking sso permissions' do
      visit settings_sso_path(locale: :en)

      expect(page).to have_text('You are not authorized to perform this action')
    end
  end
end
