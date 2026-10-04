# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::IdentitySources', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'identity_sources' => true, 'roles' => true },
      limits: { 'identity_sources' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.example.com').and_return([ '93.184.216.34' ])
  end

  describe 'GET /identity_sources' do
    it 'renders the identity sources index page' do
      source = account.with_shard do
        create(:identity_source, account: account, name: 'Clearbit CRM', source_url: 'https://api.example.com/people')
      end

      get identity_sources_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Clearbit CRM')
    end

    it 'respects non-English locale in path' do
      get identity_sources_path(locale: :es)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /identity_sources/new' do
    it 'renders the new identity source form' do
      get new_identity_source_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('identity_source[name]')
      expect(response.body).to include('identity_source[source_url]')
    end
  end

  describe 'POST /identity_sources' do
    context 'with valid parameters' do
      it 'creates an identity source with JSON key-value pairs' do
        expect {
          post identity_sources_path(locale: :en), params: {
            identity_source: {
              name: 'Internal Stripe Sync',
              description: 'Customer data sync',
              source_type: 'api',
              source_url: 'https://api.example.com/customers/{{customer.id}}',
              headers: {
                '0' => { key: 'Authorization', value: 'Bearer test_token' },
                '1' => { key: 'Accept', value: 'application/json' }
              },
              params: {
                '0' => { key: 'email', value: '{{customer.email}}' }
              },
              response_mapping: {
                '0' => { key: 'first_name', value: 'first_name' },
                '1' => { key: 'plan', value: 'custom_attributes.plan' }
              }
            }
          }
        }.to change { account.with_shard { IdentitySource.count } }.by(1)

        expect(response).to redirect_to(identity_sources_path)
        created = account.with_shard { IdentitySource.find_by(name: 'Internal Stripe Sync') }
        expect(created).to be_present
        expect(created.name).to eq('Internal Stripe Sync')
        expect(created.headers).to eq({ 'Authorization' => 'Bearer test_token', 'Accept' => 'application/json' })
        expect(created.params).to eq({ 'email' => '{{customer.email}}' })
        expect(created.response_mapping).to eq({ 'first_name' => 'first_name', 'plan' => 'custom_attributes.plan' })
      end
    end

    context 'SSRF prevention: with internal/private URLs' do
      it 'rejects localhost' do
        expect {
          post identity_sources_path(locale: :en), params: {
            identity_source: {
              name: 'Malicious Source',
              source_url: 'http://localhost:3000/internal'
            }
          }
        }.not_to change { account.with_shard { IdentitySource.count } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('cannot point to localhost or internal network spaces')
      end

      it 'rejects cloud metadata IP 169.254.169.254' do
        expect {
          post identity_sources_path(locale: :en), params: {
            identity_source: {
              name: 'Metadata Hijack',
              source_url: 'http://169.254.169.254/latest/meta-data'
            }
          }
        }.not_to change { account.with_shard { IdentitySource.count } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('cannot point to internal or private IP addresses')
      end

      it 'rejects RFC1918 private subnets' do
        expect {
          post identity_sources_path(locale: :en), params: {
            identity_source: {
              name: 'Private Subnet Attack',
              source_url: 'http://10.0.0.1/admin/secrets'
            }
          }
        }.not_to change { account.with_shard { IdentitySource.count } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('cannot point to internal or private IP addresses')
      end
    end
  end

  describe 'GET /identity_sources/:id/edit' do
    let(:identity_source) do
      account.with_shard do
        create(:identity_source, account: account, name: 'Shopify Store', source_url: 'https://api.example.com/lookup')
      end
    end

    it 'renders the edit form' do
      get edit_identity_source_path(id: identity_source.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Shopify Store')
    end
  end

  describe 'PATCH /identity_sources/:id' do
    let(:identity_source) do
      account.with_shard do
        create(:identity_source, account: account, name: 'Old Name', source_url: 'https://api.example.com/old')
      end
    end

    it 'updates attributes successfully' do
      patch identity_source_path(id: identity_source.id, locale: :en), params: {
        identity_source: {
          name: 'New Name',
          source_url: 'https://api.example.com/updated'
        }
      }
      expect(response).to redirect_to(identity_sources_path)
      account.with_shard do
        expect(identity_source.reload.name).to eq('New Name')
        expect(identity_source.source_url).to eq('https://api.example.com/updated')
      end
    end
  end

  describe 'DELETE /identity_sources/:id' do
    let!(:identity_source) do
      account.with_shard do
        create(:identity_source, account: account, name: 'To Delete', source_url: 'https://api.example.com/delete')
      end
    end

    it 'destroys the identity source' do
      expect {
        delete identity_source_path(id: identity_source.id, locale: :en)
      }.to change { account.with_shard { IdentitySource.count } }.by(-1)

      expect(response).to redirect_to(identity_sources_path)
    end
  end

  describe 'POST /identity_sources/test_connection' do
    context 'with SSRF internal URLs' do
      it 'blocks localhost and returns unprocessable entity' do
        post test_connection_identity_sources_path(locale: :en), params: {
          identity_source: {
            source_url: 'http://localhost:8080/secret'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['success']).to be false
        expect(json['error']).to include('Insecure or invalid URL')
      end

      it 'blocks cloud metadata IP 169.254.169.254' do
        post test_connection_identity_sources_path(locale: :en), params: {
          identity_source: {
            source_url: 'http://169.254.169.254/latest/meta-data'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['success']).to be false
        expect(json['error']).to include('Insecure or invalid URL')
      end
    end

    context 'with valid external URL' do
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_response) { instance_double(Net::HTTPSuccess, is_a?: true, code: '200', body: '{"user":{"id":42,"first_name":"Jane","role":"VIP"}}') }

      before do
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it 'renders liquid templates, executes test request and maps response data' do
        post test_connection_identity_sources_path(locale: :en), params: {
          identity_source: {
            source_url: 'https://api.example.com/users/{{customer.email}}',
            headers: { '0' => { key: 'X-Customer', value: '{{customer.name}}' } },
            params: { '0' => { key: 'status', value: 'active' } },
            response_mapping: {
              '0' => { key: 'user.first_name', value: 'first_name' },
              '1' => { key: 'user.role', value: 'custom_attributes.tier' }
            }
          }
        }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['success']).to be true
        expect(json['mapped_data']['first_name']).to eq('Jane')
        expect(json['mapped_data']['custom_attributes.tier']).to eq('VIP')
      end
    end
  end

  describe 'Customer Identities Integration' do
    let(:customer) { account.with_shard { create(:customer, account: account, first_name: 'Alice', email: 'alice@example.com') } }
    let(:source) { account.with_shard { create(:identity_source, account: account, name: 'Acme CRM', source_url: 'https://api.example.com/customers') } }
    let!(:identity) do
      account.with_shard do
        create(:identity,
          account: account,
          customer: customer,
          identity_source: source,
          identity_type: :custom_api,
          identifier: 'crm_9876',
          external_id: 'ext_9876',
          custom_attributes: { 'tier' => 'enterprise', 'ltv' => 5000 }
        )
      end
    end

    it 'displays connected customer identities and custom attributes on customer show page' do
      get customer_path(id: customer.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Acme CRM')
      expect(response.body).to include('ext_9876')
      expect(response.body).to include('crm_9876')
    end
  end
end
