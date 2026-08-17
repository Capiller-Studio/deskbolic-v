# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'channels' => { 'email' => true, 'instagram' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:email_channel) { account.with_shard { create(:channel_email, account: account, email: "test_#{SecureRandom.hex(4)}@acme.com") } }

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

  describe 'Instagram Channels' do
    let(:instagram_channel) do
      account.with_shard do
        create(:channel_instagram, account: account, name: 'Main Instagram', instagram_id: "ig_#{SecureRandom.hex(4)}")
      end
    end

    describe 'GET /channels/instagram' do
      it 'renders instagram channels index' do
        get channels_instagram_index_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/instagram/new' do
      it 'renders new instagram channel form' do
        get new_channels_instagram_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/instagram/oauth_authorize' do
      it 'redirects to Instagram OAuth authorize URL' do
        get oauth_authorize_channels_instagram_index_path(locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://api.instagram.com/oauth/authorize')
      end
    end

    describe 'GET /channels/instagram/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :instagram, :app_secret).and_return(secret)
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_instagram_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        let(:oauth_service) { instance_double(Channels::Instagram::OauthService) }

        before do
          allow(Channels::Instagram::OauthService).to receive(:new).with(account: account).and_return(oauth_service)
          allow(oauth_service).to receive(:exchange_code).and_return({
            access_token: 'ig_long_lived_token',
            expires_at: 60.days.from_now,
            user: { id: '987654321', username: 'acme_ig', name: 'Acme IG', avatar_url: 'https://example.com/avatar.jpg' }
          })
        end

        it 'exchanges the code, creates the channel, and redirects to edit' do
          get callback_channels_instagram_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:redirect)
          expect(account.with_shard { Channel::Instagram.where(instagram_id: '987654321') }).to exist
        end
      end
    end

    describe 'PATCH /channels/instagram/:id' do
      it 'updates instagram channel name' do
        patch channels_instagram_path(id: instagram_channel.id, locale: :en), params: {
          instagram_channel: { name: 'Updated Instagram Name' }
        }
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { instagram_channel.reload.name }).to eq('Updated Instagram Name')
      end
    end

    describe 'DELETE /channels/instagram/:id' do
      it 'destroys instagram channel' do
        delete channels_instagram_path(id: instagram_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::Instagram.where(id: instagram_channel.id) }).not_to exist
      end
    end
  end
end
