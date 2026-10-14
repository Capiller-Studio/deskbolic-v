# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhook Integrations Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Webhooks Enterprise', identifier: 'webhooks-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Parabolic Enterprise Plan',
      features: {
        'roles' => true,
        'channels' => { 'custom' => true }
      },
      limits: {
        'users' => 20
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'allows an admin to configure, view secret & instructions, edit, and delete an outbound webhook integration' do
    # 1. Visit Integrations index
    visit "#{Capybara.app_host}#{integrations_path(locale: :en)}"
    expect(page).to have_current_path(%r{/integrations})
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.index.title', default: 'Integrations'))

    # 2. Click "+ Connect" / "+ New Webhook"
    find('a.ui-settings-page__action--webhook').click
    expect(page).to have_current_path(%r{/integrations/new\?provider=webhook})
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.new.title', provider: 'Webhook', default: 'New Webhook Integration'))

    # 3. Fill in Webhook configuration
    fill_in 'integration[name]', with: 'Production Event Broker'
    fill_in 'integration[settings][webhook_url]', with: 'https://broker.example.com/events'

    # Select event toggles
    check 'event_conversation-created', allow_label_click: true
    check 'event_message-created', allow_label_click: true

    # 4. Save Webhook
    find('button[form="integration-form"]').click

    # 5. Redirected to index with success notice
    expect(page).to have_current_path(%r{/integrations})
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.created', default: 'Integration created successfully'))
    expect(page).to have_text('Configured')

    # Verify database persistence on tenant shard
    integration = account.with_shard do
      account.integrations.find_by(name: 'Production Event Broker', provider: :webhook)
    end
    expect(integration).to be_present
    expect(integration.webhook_url).to eq('https://broker.example.com/events')
    expect(integration.webhook_secret).to be_present
    expect(integration.subscribed_events).to include('conversation.created', 'message.created')

    # 6. Click Edit on the configured Webhook
    find("a[href*='/integrations/#{integration.id}/edit']").click
    expect(page).to have_current_path(%r{/integrations/#{integration.id}/edit})

    # Verify secret is displayed in read-only field
    secret_field = find("input[value='#{integration.webhook_secret}']")
    expect(secret_field).to be_present
    expect(secret_field[:readonly]).to eq('true')

    # Verify payload documentation and HMAC instructions are visible
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.webhooks.instructions_title', default: 'Webhook Documentation'))
    expect(page).to have_css('pre.ui-code-block')

    # 7. Update Webhook URL and save
    fill_in 'integration[settings][webhook_url]', with: 'https://broker.example.com/events/v2'
    find('button[form="integration-form"]').click

    expect(page).to have_current_path(%r{/integrations})
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.updated', default: 'Integration updated successfully'))

    account.with_shard do
      expect(integration.reload.webhook_url).to eq('https://broker.example.com/events/v2')
    end

    # 8. Delete Webhook Integration
    page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
    find("a[href*='/integrations/#{integration.id}'][data-turbo-method='delete']").click

    expect(page).to have_current_path(%r{/integrations})
    expect(page).to have_text(I18n.t('dashboard.settings.integrations.destroyed', default: 'Integration disconnected successfully'))

    account.with_shard do
      expect(account.integrations.where(id: integration.id)).to be_empty
    end
  end

  it 'prevents submission when webhook url is missing and remains on form' do
    visit "#{Capybara.app_host}#{new_integration_path(provider: :webhook, locale: :en)}"
    fill_in 'integration[name]', with: 'Incomplete Webhook'
    
    # Try submitting without webhook_url (remove required attribute via JS to test backend model validation)
    page.execute_script("document.querySelector('input[name=\"integration[settings][webhook_url]\"]').removeAttribute('required')")
    find('button[form="integration-form"]').click

    # Remains on form or returns unprocessable entity
    expect(page).to have_current_path(%r{/integrations})
    expect(account.with_shard { account.integrations.where(name: 'Incomplete Webhook') }).to be_empty
  end
end
