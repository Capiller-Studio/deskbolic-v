# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'channels' => { 'email' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:email_channel) { create(:channel_email, account: account, email: "test_#{SecureRandom.hex(4)}@acme.com") }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /channels/email' do
    it 'renders email channels index' do
      get channels_email_index_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /channels/email/new' do
    it 'renders new email channel form' do
      get new_channels_email_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /channels/email/:id' do
    it 'updates email channel name' do
      patch channels_email_path(id: email_channel.id, locale: :en), params: {
        email_channel: { name: 'Support New Name' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { email_channel.reload.name }).to eq('Support New Name')
    end
  end

  describe 'DELETE /channels/email/:id' do
    it 'destroys email channel' do
      delete channels_email_path(id: email_channel.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Channel::Email.where(id: email_channel.id) }).not_to exist
    end
  end
end
