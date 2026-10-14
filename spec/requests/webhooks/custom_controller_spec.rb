# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::CustomController Request Spec', type: :request do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }

  let(:custom_channel) do
    account.with_shard do
      channel = create(:channel_custom, account: account, name: 'Warehouse Ingestion Hook')
      create(:inbox, channel: channel, account: account, primary_inbox: true)
      channel
    end
  end

  let(:valid_token) { custom_channel.hmac_token }
  let(:endpoint_url) { "/webhooks/custom/#{account.id}/#{custom_channel.id}" }

  let(:payload) do
    {
      event: 'message.created',
      customer: {
        email: 'supplier@logistics.example.com',
        name: 'Logistics Supplier',
        external_id: 'SUP-9988'
      },
      message: {
        content: 'Shipment #4521 has departed warehouse'
      },
      conversation: {
        title: 'Shipment Tracking #4521',
        external_id: 'SHIP-CONV-4521'
      }
    }
  end

  describe 'Authentication & Authorization Edge Cases' do
    it 'returns 401 Unauthorized when X-Deskbolic-Token header is completely missing' do
      expect {
        post endpoint_url, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
      }.not_to change(Webhook::Incoming, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 Unauthorized when X-Deskbolic-Token header is empty string' do
      post endpoint_url, params: payload.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'X-Deskbolic-Token' => ''
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 Unauthorized when X-Deskbolic-Token header contains an invalid token' do
      post endpoint_url, params: payload.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'X-Deskbolic-Token' => 'forged_fake_token_123456789'
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 Not Found when channel does not exist' do
      post "/webhooks/custom/#{account.id}/#{SecureRandom.uuid}", params: payload.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'X-Deskbolic-Token' => valid_token
      }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 Not Found when account does not match channel account_id' do
      post "/webhooks/custom/#{other_account.id}/#{custom_channel.id}", params: payload.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'X-Deskbolic-Token' => valid_token
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Successful Webhook Ingestion' do
    it 'accepts valid token, creates Webhook::Incoming record, and enqueues CustomEventListenWorker' do
      expect(Webhooks::CustomEventListenWorker).to receive(:perform_async).with(kind_of(String)).and_call_original

      expect {
        post endpoint_url, params: payload.to_json, headers: {
          'CONTENT_TYPE' => 'application/json',
          'X-Deskbolic-Token' => valid_token
        }
      }.to change(Webhook::Incoming, :count).by(1)

      expect(response).to have_http_status(:ok)

      incoming = Webhook::Incoming.last
      expect(incoming.source).to eq('custom')
      expect(incoming.status).to eq('processed')
      expect(incoming.payload['event']).to eq('message.created')
      expect(incoming.payload['message']['content']).to eq('Shipment #4521 has departed warehouse')
      expect(incoming.request_url).to include(endpoint_url)

      # Verify database persistence of conversation & message
      account.with_shard do
        created_conversation = account.conversations.find_by(external_id: 'SHIP-CONV-4521')
        expect(created_conversation).to be_present
        expect(created_conversation.title).to eq('Shipment Tracking #4521')
        expect(created_conversation.messages.last.content).to eq('Shipment #4521 has departed warehouse')
      end
    end
  end
end
