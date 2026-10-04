# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom Channels Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Apex Tech', identifier: 'apex-tech') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'roles' => true, 'channels' => { 'custom' => true } },
      limits: { 'channels' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let(:mock_http) { instance_double(Net::HTTP) }
  let(:mock_response) do
    instance_double(Net::HTTPSuccess, is_a?: true, code: '200', body: '{"received":true,"status":"ok"}')
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.erp-system.com').and_return([ '93.184.216.34' ])

    allow(Net::HTTP).to receive(:new).and_call_original
    allow(Net::HTTP).to receive(:new).with('api.erp-system.com', 443).and_return(mock_http)
    allow(mock_http).to receive(:use_ssl=)
    allow(mock_http).to receive(:open_timeout=)
    allow(mock_http).to receive(:read_timeout=)
    allow(mock_http).to receive(:request).and_return(mock_response)

    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'creates a custom channel, displays credentials card with HMAC token, and tests sandbox simulator' do
    # 1. Visit New Custom Channel page
    visit "#{Capybara.app_host}#{new_channels_custom_path(locale: :en)}"
    expect(page).to have_text(I18n.t('dashboard.custom_channels.new.title', default: 'Add New Custom Channel')).or have_field('channel_custom[name]')

    # 2. Fill in Channel details
    fill_in 'channel_custom[name]', with: 'Internal ERP Bot'
    fill_in 'channel_custom[webhook_url]', with: 'https://api.erp-system.com/webhook'

    # 3. Submit and create channel
    find('button[form="custom-channel-form"]').click

    # 4. Verify redirected to edit page with credentials card
    expect(page).to have_text(I18n.t('dashboard.channels.edit.integration_details', default: 'Integration Details'))

    # Verify database persistence on tenant shard
    channel = account.with_shard { Channel::Custom.find_by(name: 'Internal ERP Bot', account: account) }
    expect(channel).to be_present
    expect(channel.webhook_secret).to be_present
    expect(channel.hmac_token).to be_present
    expect(channel.webhook_endpoint).to be_present

    # 5. Verify credentials card displays HMAC token and incoming endpoint
    expect(page).to have_field(with: channel.webhook_endpoint)
    expect(page).to have_field(with: channel.hmac_token)

    # 6. Test Sandbox Simulator - Fire Outbound
    outbound_btn = find('button[data-action="click->test-webhook#fireOutbound"]')
    outbound_btn.click

    expect(page).to have_text('200 SUCCESS')
    expect(page).to have_text('"received": true')

    # 7. Test Sandbox Simulator - Test Inbound Mapping
    inbound_btn = find('button[data-action="click->test-webhook#testInbound"]')
    inbound_btn.click

    expect(page).to have_css('[data-test-webhook-target="inboundResult"]', visible: :visible)
  end

  it 'blocks SSRF attempts to private/internal URLs when creating or testing webhooks' do
    visit "#{Capybara.app_host}#{new_channels_custom_path(locale: :en)}"

    fill_in 'channel_custom[name]', with: 'Exploit Channel'
    fill_in 'channel_custom[webhook_url]', with: 'http://169.254.169.254/latest/meta-data'

    find('button[form="custom-channel-form"]').click
    expect(page).to have_text(/Insecure or invalid|Failed to create/i)
  end
end
