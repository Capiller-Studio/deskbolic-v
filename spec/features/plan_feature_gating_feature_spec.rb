# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plan Feature Gating Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Apex Corp', identifier: 'apex-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:basic_plan) do
    create(:plan,
      name: 'Starter Plan',
      features: { 'roles' => true },
      limits: { 'channels' => 2, 'users' => 5 }
    )
  end

  let!(:subscription) { create(:subscription, account: account, plan: basic_plan, status: :active) }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.apex-corp.com').and_return([ '93.184.216.34' ])

    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'enforces plan feature locks in UI sidebar, blocks direct navigation, and unlocks creation upon plan upgrade' do
    # 1. Visit settings index and verify lock badges on locked features
    visit "#{Capybara.app_host}#{settings_path(locale: :en)}"
    expect(page).to have_css('.plan-upgrade-lock', minimum: 1)

    # 2. Directly visit a locked feature endpoint in browser (Custom Channels)
    visit "#{Capybara.app_host}#{channels_custom_index_path(locale: :en)}"

    # 3. Verify redirected to billing with feature upgrade notice
    expect(page).to have_current_path(%r{/billing})
    expect(page).to have_text("The feature 'Custom Channels' is not available on your current plan. Please upgrade to access it.")

    # 4. Directly visit another locked creation URL (Identity Sources)
    visit "#{Capybara.app_host}#{new_identity_source_path(locale: :en)}"
    expect(page).to have_current_path(%r{/billing})
    expect(page).to have_text("The feature 'Identity Sources' is not available on your current plan. Please upgrade to access it.")

    # 5. Upgrade the account's plan with premium features
    basic_plan.update!(
      features: {
        'roles' => true,
        'channels' => { 'custom' => true },
        'identity_sources' => true,
        'sla' => true,
        'business_hours' => true,
        'automations' => true,
        'custom_fields' => true
      },
      limits: {
        'channels' => 50,
        'users' => 50
      }
    )

    # 6. Revisit settings: custom channels and identity sources lock badges are now unlocked
    visit "#{Capybara.app_host}#{settings_path(locale: :en)}"

    # 7. Visit Custom Channel creation page (now unlocked)
    visit "#{Capybara.app_host}#{new_channels_custom_path(locale: :en)}"
    expect(page).to have_field('channel_custom[name]')
    expect(page).to have_no_current_path(%r{/billing})

    # 8. Successfully create custom channel record
    fill_in 'channel_custom[name]', with: 'Unlocked ERP Channel'
    fill_in 'channel_custom[webhook_url]', with: 'https://api.apex-corp.com/webhook'
    find('button[form="custom-channel-form"]').click

    # 9. Verify channel created and redirected to edit view
    expect(page).to have_text(I18n.t('dashboard.channels.edit.integration_details', default: 'Integration Details'))

    created_channel = account.with_shard { Channel::Custom.where(account_id: account.id, name: 'Unlocked ERP Channel').first }
    expect(created_channel).to be_present
    expect(created_channel.webhook_url).to eq('https://api.apex-corp.com/webhook')
  end
end
