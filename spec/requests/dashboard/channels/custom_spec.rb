# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels::Custom', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'roles' => true, 'channels' => { 'custom' => true } },
      limits: { 'channels' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:custom_channel) do
    account.with_shard do
      channel = create(:channel_custom, account: account, name: 'Billing Hook App', webhook_url: 'https://example.com/webhook')
      create(:inbox, channel: channel, account: account, primary_inbox: true)
      channel
    end
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return([ '93.184.216.34' ])
  end

  describe 'GET /channels/custom' do
    it 'renders the custom channels index' do
      custom_channel
      get channels_custom_index_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Billing Hook App')
    end

    it 'supports non-English locales' do
      get channels_custom_index_path(locale: :es)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /channels/custom/new' do
    it 'renders the new custom channel form' do
      get new_channels_custom_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('channel_custom[name]')
      expect(response.body).to include('channel_custom[webhook_url]')
    end
  end

  describe 'POST /channels/custom' do
    context 'with valid parameters' do
      it 'creates a custom channel with primary inbox, secret and hmac token' do
        expect {
          post channels_custom_index_path(locale: :en), params: {
            channel_custom: {
              name: 'Support API Bridge',
              description: 'External support hook',
              webhook_url: 'https://example.com/events'
            }
          }
        }.to change { account.with_shard { Channel::Custom.count } }.by(1)

        expect(response).to have_http_status(:redirect)
        created = account.with_shard { Channel::Custom.find_by(name: 'Support API Bridge') }
        expect(created).to be_present
        expect(created.webhook_secret).to be_present
        expect(created.hmac_token).to be_present
        expect(created.primary_inbox).to be_present
      end
    end

    context 'SSRF prevention: with internal/private URLs' do
      it 'rejects localhost' do
        expect {
          post channels_custom_index_path(locale: :en), params: {
            channel_custom: {
              name: 'Internal Attack',
              webhook_url: 'http://localhost:3000/internal_hook'
            }
          }
        }.not_to change { account.with_shard { Channel::Custom.count } }

        expect(response).to redirect_to(new_channels_custom_path)
      end

      it 'rejects cloud metadata IP' do
        expect {
          post channels_custom_index_path(locale: :en), params: {
            channel_custom: {
              name: 'Metadata Exfiltration',
              webhook_url: 'http://169.254.169.254/latest/meta-data'
            }
          }
        }.not_to change { account.with_shard { Channel::Custom.count } }

        expect(response).to redirect_to(new_channels_custom_path)
      end
    end

    context 'when plan limit is reached' do
      before do
        plan.update!(limits: { 'channels' => 0, 'users' => 10 })
      end

      it 'denies creation and redirects with limit alert' do
        post channels_custom_index_path(locale: :en), params: {
          channel_custom: {
            name: 'Over Limit Channel',
            webhook_url: 'https://example.com/hook'
          }
        }
        expect(response).to redirect_to(dashboard_billing_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET /channels/custom/:id' do
    it 'renders the channel show view' do
      get channels_custom_path(id: custom_channel.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(custom_channel.name)
    end
  end

  describe 'GET /channels/custom/:id/edit' do
    it 'renders the edit channel form' do
      get edit_channels_custom_path(id: custom_channel.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(custom_channel.name)
    end
  end

  describe 'PATCH /channels/custom/:id' do
    it 'updates channel name and headers' do
      patch channels_custom_path(id: custom_channel.id, locale: :en), params: {
        channel_custom: {
          name: 'Updated Custom Bridge',
          headers: {
            '0' => { key: 'X-App-ID', value: 'my_app_123' }
          }
        }
      }
      expect(response).to redirect_to(channels_custom_index_path)
      account.with_shard do
        custom_channel.reload
        expect(custom_channel.name).to eq('Updated Custom Bridge')
        expect(custom_channel.headers).to eq({ 'X-App-ID' => 'my_app_123' })
      end
    end
  end

  describe 'DELETE /channels/custom/:id' do
    it 'destroys the custom channel and its inboxes' do
      channel_id = custom_channel.id
      expect {
        delete channels_custom_path(id: channel_id, locale: :en)
      }.to change { account.with_shard { Channel::Custom.count } }.by(-1)

      expect(response).to redirect_to(channels_custom_index_path)
      expect(account.with_shard { Channel::Custom.where(id: channel_id) }).not_to exist
    end
  end

  describe 'POST /channels/custom/:id/test_outgoing_webhook' do
    context 'with SSRF internal URL' do
      it 'blocks localhost and returns unprocessable entity' do
        account.with_shard { custom_channel.update_columns(webhook_url: 'http://localhost:8080/drain') }

        post test_outgoing_webhook_channels_custom_path(id: custom_channel.id, locale: :en)
        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to include('Insecure or invalid webhook URL')
      end
    end

    context 'with valid external URL' do
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_response) { instance_double(Net::HTTPSuccess, code: '200', body: '{"received":true}') }

      before do
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it 'sends outgoing webhook with Deskbolic-Signature header' do
        post test_outgoing_webhook_channels_custom_path(id: custom_channel.id, locale: :en)
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['received']).to be true
      end
    end
  end

  describe 'POST /channels/custom/:id/test_incoming_webhook' do
    it 'extracts mapped attributes from simulated payload' do
      account.with_shard do
        custom_channel.update_columns(
          response_mapping: { 'user_name' => 'customer.profile.name', 'ticket_id' => 'ticket.id' }
        )
      end

      post test_incoming_webhook_channels_custom_path(id: custom_channel.id, locale: :en), params: {
        payload: {
          customer: { profile: { name: 'Bob Dylan' } },
          ticket: { id: 'T-999' }
        }.to_json
      }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['mapped_result']['user_name']).to eq('Bob Dylan')
      expect(json['mapped_result']['ticket_id']).to eq('T-999')
    end

    it 'returns unprocessable entity on invalid JSON' do
      post test_incoming_webhook_channels_custom_path(id: custom_channel.id, locale: :en), params: {
        payload: 'not-json'
      }
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to eq('Invalid JSON payload')
    end
  end

  describe 'POST /webhooks/custom/:account_id/:channel_id (Inbound webhook endpoint)' do
    before do
      set_subdomain(nil) # Access apex/unscoped webhook route
    end

    it 'rejects requests without X-Deskbolic-Token with 401 unauthorized' do
      post "/webhooks/custom/#{account.id}/#{custom_channel.id}", params: { event: 'test' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects requests with incorrect token with 401 unauthorized' do
      post "/webhooks/custom/#{account.id}/#{custom_channel.id}",
        params: { event: 'test' },
        headers: { 'X-Deskbolic-Token' => 'wrong_token' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 if channel does not exist' do
      post "/webhooks/custom/#{account.id}/non-existent-channel-id",
        params: { event: 'test' },
        headers: { 'X-Deskbolic-Token' => custom_channel.hmac_token }

      expect(response).to have_http_status(:not_found)
    end

    it 'accepts valid webhook, records incoming webhook, and enqueues CustomEventListenWorker' do
      expect(Webhooks::CustomEventListenWorker).to receive(:perform_async).with(kind_of(String))

      expect {
        post "/webhooks/custom/#{account.id}/#{custom_channel.id}",
          params: { event: 'message.received', content: 'Hello Deskbolic support' },
          headers: { 'X-Deskbolic-Token' => custom_channel.hmac_token }
      }.to change { account.with_shard { Webhook::Incoming.count } }.by(1)

      expect(response).to have_http_status(:ok)
    end
  end
end
