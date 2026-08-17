# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::CustomFields', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'custom_fields' => true }, limits: { 'custom_fields' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:custom_field) { create(:custom_field, account: account, key: 'order_number', entity_type: 'conversation') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /custom_fields' do
    it 'renders custom fields index' do
      get custom_fields_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /custom_fields/new' do
    it 'renders new custom field form' do
      get new_custom_field_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /custom_fields' do
    it 'creates a new custom field' do
      post custom_fields_path(locale: :en), params: {
        custom_field: {
          key: 'loyalty_tier',
          entity_type: 'customer',
          field_type: 'text',
          required: false
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { CustomField.where(key: 'loyalty_tier') }).to exist
    end
  end

  describe 'DELETE /custom_fields/:id' do
    it 'destroys custom field' do
      delete custom_field_path(id: custom_field.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { CustomField.where(id: custom_field.id) }).not_to exist
    end
  end
end
