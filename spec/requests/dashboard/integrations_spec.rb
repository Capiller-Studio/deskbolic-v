# frozen_string_literal: true

require 'rails_helper'
require 'jwt'

RSpec.describe 'Dashboard::Integrations', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'integrations' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  around do |example|
    original_client_id = ENV['SLACK_CLIENT_ID']
    original_client_secret = ENV['SLACK_CLIENT_SECRET']
    ENV['SLACK_CLIENT_ID'] = 'test_slack_client_id' if ENV['SLACK_CLIENT_ID'].blank?
    ENV['SLACK_CLIENT_SECRET'] = 'test_slack_client_secret' if ENV['SLACK_CLIENT_SECRET'].blank?
    example.run
  ensure
    ENV['SLACK_CLIENT_ID'] = original_client_id
    ENV['SLACK_CLIENT_SECRET'] = original_client_secret
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /integrations' do
    it 'renders integrations index page' do
      get integrations_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Slack')
    end
  end

  describe 'GET /integrations/slack/oauth_authorize' do
    it 'redirects to Slack authorization URL with state' do
      get slack_oauth_authorize_integrations_path(locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(response.redirect_url).to include('https://slack.com/oauth/v2/authorize')
      expect(response.redirect_url).to include('scope=incoming-webhook')
      expect(response.redirect_url).to include('state=')
    end
  end

  describe 'GET /integrations/slack/callback' do
    let(:secret) { Rails.application.credentials.dig(:integrations, :slack, :signing_secret) || Rails.application.secret_key_base }
    let(:valid_state) do
      payload = { sub: account.id, iat: Time.current.to_i, exp: 15.minutes.from_now.to_i }
      JWT.encode(payload, secret, 'HS256')
    end

    it 'exchanges authorization code and creates Slack integration' do
      slack_response = {
        'ok' => true,
        'access_token' => 'xoxb-test-token',
        'bot_user_id' => 'U12345',
        'team' => { 'id' => 'T123', 'name' => 'Deskbolic Workspace' },
        'incoming_webhook' => {
          'channel' => '#support',
          'channel_id' => 'C123',
          'url' => 'https://hooks.slack.com/services/T123/B123/XXXXX'
        }
      }

      allow(Net::HTTP).to receive(:post_form).and_return(
        double(body: slack_response.to_json)
      )

      get slack_callback_integrations_path(code: 'test_code_123', state: valid_state, locale: :en)

      expect(response).to redirect_to(integrations_path)
      follow_redirect!
      expect(response.body).to include('Successfully connected to #support!')

      integration = account.integrations.find_by(provider: :slack)
      expect(integration).to be_present
      expect(integration.settings['channel']).to eq('#support')
      expect(integration.settings['webhook_url']).to eq('https://hooks.slack.com/services/T123/B123/XXXXX')
      expect(integration.credentials['access_token']).to eq('xoxb-test-token')
      expect(integration.credentials['bot_user_id']).to eq('U12345')
      expect(integration.metadata['team_name']).to eq('Deskbolic Workspace')
      expect(integration.metadata['team_id']).to eq('T123')
    end

    it 'redirects with error if authorization code is missing or user denied' do
      get slack_callback_integrations_path(error: 'access_denied', locale: :en)
      expect(response).to redirect_to(integrations_path)
    end
  end

  describe 'POST /integrations/slack/test' do
    let!(:slack_integration) do
      create(:integration, account: account, provider: :slack, status: :active, settings: {
        'webhook_url' => 'https://hooks.slack.com/services/T123/B123/XXXXX',
        'channel' => '#support'
      })
    end

    it 'creates a Webhook::Delivery and queues a test notification to Slack' do
      expect(Integrations::Slack::NotifierWorker).to receive(:perform_async).with(
        account.id,
        an_instance_of(String),
        1
      )

      expect {
        post slack_test_integrations_path(locale: :en)
      }.to change(Webhook::Delivery, :count).by(1)

      delivery = slack_integration.webhook_deliveries.last
      expect(delivery.account).to eq(account)
      expect(delivery.resource).to eq(slack_integration)
      expect(delivery.event_name).to eq('message.created')
      expect(delivery.endpoint_url).to eq(slack_integration.webhook_url)
      expect(delivery.request_payload['source']).to eq('Deskbolic Test')

      expect(response).to redirect_to(integrations_path)
      follow_redirect!
      expect(response.body).to include('Test notification sent to #support!')
    end
  end
end
