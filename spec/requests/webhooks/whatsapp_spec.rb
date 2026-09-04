# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Whatsapp', type: :request do
  let(:account) { create(:account) }
  let(:channel) { account.with_shard { create(:channel_whatsapp, account: account) } }

  describe 'GET /webhooks/whatsapp (Embedded Hub verification)' do
    before do
      allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :verify_token).and_return('meta_verify_token_123')
    end

    it 'returns the challenge when hub.verify_token matches global verify token' do
      get '/webhooks/whatsapp', params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => 'meta_verify_token_123',
        'hub.challenge' => 'challenge_code_abc'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('challenge_code_abc')
    end

    it 'returns 401 unauthorized when hub.verify_token does not match' do
      get '/webhooks/whatsapp', params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => 'wrong_token',
        'hub.challenge' => 'challenge_code_abc'
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq({ 'error' => 'Invalid Token' })
    end

    it 'returns 401 unauthorized when hub.verify_token is blank' do
      get '/webhooks/whatsapp', params: {
        'hub.mode' => 'subscribe',
        'hub.challenge' => 'challenge_code_abc'
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /webhooks/whatsapp/:account_id/:channel_id (Per-channel Hub verification)' do
    it 'returns the challenge when hub.verify_token matches channel.webhook_secret' do
      get "/webhooks/whatsapp/#{account.id}/#{channel.id}", params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => channel.webhook_secret,
        'hub.challenge' => 'manual_challenge_xyz'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('manual_challenge_xyz')
    end

    it 'returns 401 unauthorized when hub.verify_token does not match channel secret' do
      get "/webhooks/whatsapp/#{account.id}/#{channel.id}", params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => 'invalid_secret',
        'hub.challenge' => 'manual_challenge_xyz'
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when account does not exist' do
      get "/webhooks/whatsapp/#{SecureRandom.uuid}/#{channel.id}", params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => channel.webhook_secret,
        'hub.challenge' => 'manual_challenge_xyz'
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /webhooks/whatsapp (Incoming webhook notification)' do
    let(:payload) do
      {
        'object' => 'whatsapp_business_account',
        'entry' => [
          {
            'id' => channel.business_account_id,
            'changes' => [
              {
                'value' => {
                  'messaging_product' => 'whatsapp',
                  'metadata' => {
                    'display_phone_number' => '15551234567',
                    'phone_number_id' => channel.phone_number_id
                  },
                  'messages' => [
                    {
                      'from' => '15559876543',
                      'id' => 'wamid.HBgLMTU1NTk4NzY1NDMVAgASGBQzQT',
                      'timestamp' => '1600000000',
                      'text' => { 'body' => 'Hello from customer' },
                      'type' => 'text'
                    }
                  ]
                },
                'field' => 'messages'
              }
            ]
          }
        ]
      }
    end

    it 'stores incoming webhook and enqueues Webhooks::WhatsappEventListenWorker' do
      expect(Webhooks::WhatsappEventListenWorker).to receive(:perform_async).with(an_instance_of(String))

      expect do
        post '/webhooks/whatsapp', params: payload, as: :json
      end.to change(Webhook::Incoming, :count).by(1)

      expect(response).to have_http_status(:ok)

      incoming = Webhook::Incoming.last
      expect(incoming.source).to eq('whatsapp')
      expect(incoming.payload['object']).to eq('whatsapp_business_account')
    end

    it 'handles per-channel endpoint POST /webhooks/whatsapp/:account_id/:channel_id' do
      expect(Webhooks::WhatsappEventListenWorker).to receive(:perform_async).with(an_instance_of(String))

      expect do
        post "/webhooks/whatsapp/#{account.id}/#{channel.id}", params: payload, as: :json
      end.to change(Webhook::Incoming, :count).by(1)

      expect(response).to have_http_status(:ok)
    end
  end
end
