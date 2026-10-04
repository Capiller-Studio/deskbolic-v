# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Identity Sources Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Acme Enterprise', identifier: 'acme-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'identity_sources' => true, 'roles' => true },
      limits: { 'identity_sources' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let(:mock_http) { instance_double(Net::HTTP) }
  let(:mock_response) do
    instance_double(Net::HTTPSuccess, is_a?: true, code: '200', body: '{"user":{"id":42,"first_name":"Jane","email":"test@example.com"}}')
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.crm-partner.com').and_return([ '93.184.216.34' ])

    allow(Net::HTTP).to receive(:new).and_call_original
    allow(Net::HTTP).to receive(:new).with('api.crm-partner.com', 443).and_return(mock_http)
    allow(mock_http).to receive(:use_ssl=)
    allow(mock_http).to receive(:verify_mode=)
    allow(mock_http).to receive(:open_timeout=)
    allow(mock_http).to receive(:read_timeout=)
    allow(mock_http).to receive(:request).and_return(mock_response)

    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'allows navigation, test run connection, creating and editing an identity source' do
    # 1. Visit Identity Sources Index
    visit "#{Capybara.app_host}#{identity_sources_path(locale: :en)}"
    expect(page).to have_text(I18n.t('dashboard.identity_sources.index.title'))

    # 2. Click Add New Identity Source
    find_by_id('new-identity-source').click
    expect(page).to have_text(I18n.t('dashboard.identity_sources.new.title'))

    # 3. Fill in details
    fill_in 'identity-source-name', with: 'Partner CRM Integration'
    fill_in 'identity-source-description', with: 'Real-time customer data lookup'
    fill_in 'identity-source-source-url', with: 'https://api.crm-partner.com/users/{{ customer.email }}'

    # 4. Add a Custom Header
    header_add_btn = page.first('button.is-section-add-btn')
    header_add_btn.click
    find('input[name*="[headers]"][name*="[key]"]').set('Authorization')
    find('input[name*="[headers]"][name*="[value]"]').set('Bearer test-api-key-999')

    # 5. Add a Response Mapping
    mapping_add_btn = page.all('button.is-section-add-btn').last
    mapping_add_btn.click
    find('input[name*="[response_mapping]"][name*="[key]"]').set('user.first_name')
    page.execute_script(<<~JS)
      const mappingSelect = document.querySelector('select[name*="[response_mapping]"][name*="[value]"]');
      if (mappingSelect) {
        mappingSelect.value = 'first_name';
        mappingSelect.dispatchEvent(new Event('change', { bubbles: true }));
      }
    JS

    # 6. Test Run Connection
    first('button[data-action="click->key-value-builder#testRun"]').click
    expect(page).to have_css('.ap-test-result', visible: :visible)
    expect(page).to have_text('Mapped Fields')
    expect(page).to have_text('Jane')

    # 7. Submit and Save Form
    find('button[form="identity-source-form"]').click

    # 8. Verify redirection and listing
    expect(page).to have_text('Partner CRM Integration')
    expect(page).to have_text('Real-time customer data lookup')

    # Verify database persistence on tenant shard
    source = account.with_shard { account.identity_sources.find_by(name: 'Partner CRM Integration') }
    expect(source).to be_present
    expect(source.source_url).to eq('https://api.crm-partner.com/users/{{ customer.email }}')
    expect(source.headers).to eq({ 'Authorization' => 'Bearer test-api-key-999' })
    expect(source.response_mapping).to eq({ 'user.first_name' => 'first_name' })

    # 9. Edit the Identity Source
    visit "#{Capybara.app_host}#{edit_identity_source_path(source, locale: :en)}"
    expect(page).to have_field('identity-source-name', with: 'Partner CRM Integration')

    fill_in 'identity-source-description', with: 'Updated description for CRM sync'
    find('button[form="identity-source-form"]').click

    expect(page).to have_text('Partner CRM Integration')
    expect(source.reload.description).to eq('Updated description for CRM sync')
  end

  it 'blocks SSRF internal and cloud metadata IPs during test run' do
    visit "#{Capybara.app_host}#{new_identity_source_path(locale: :en)}"

    fill_in 'identity-source-name', with: 'Malicious Source'
    fill_in 'identity-source-source-url', with: 'http://169.254.169.254/latest/meta-data'

    first('button[data-action="click->key-value-builder#testRun"]').click
    expect(page).to have_css('.ap-test-result', visible: :visible)
    expect(page).to have_text('Insecure or invalid URL')
  end
end
