# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'channels' => { 'email' => true, 'instagram' => true, 'whatsapp' => true, 'facebook' => true } }, limits: { 'channels' => 100, 'users' => 100 })
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

  describe 'Facebook Pages Channels' do
    describe 'GET /channels/facebook/oauth_authorize' do
      it 'redirects to Meta dialog oauth URL' do
        get oauth_authorize_channels_facebook_index_path(locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.facebook.com')
        expect(response.location).to include('dialog/oauth')
      end
    end

    describe 'GET /channels/facebook/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :facebook, :app_secret).and_return(secret)
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :facebook, :app_id).and_return('fb_app_123')
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_facebook_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        before do
          allow(Channels::FacebookPages::TokenExchangeService).to receive(:call).and_return({
            user_access_token: 'user_token',
            pages: [
              { id: 'page_123', name: 'My Page', access_token: 'page_token', category: 'Business', avatar_url: nil, already_connected: false }
            ]
          })
        end

        it 'exchanges the code and renders page selection' do
          get callback_channels_facebook_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('My Page')
        end
      end
    end
  end

  describe 'WhatsApp Channels' do
    let(:phone_suffix) { SecureRandom.random_number(1000000..9999999).to_s }
    let(:whatsapp_channel) do
      account.with_shard do
        create(:channel_whatsapp, account: account, name: 'Support WhatsApp', full_phone_number: "+1555#{phone_suffix}", phone_number_id: "phone_#{phone_suffix}", business_account_id: "waba_#{phone_suffix}")
      end
    end

    describe 'GET /channels/whatsapp' do
      it 'renders whatsapp channels index' do
        get channels_whatsapp_index_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/whatsapp/new' do
      it 'renders new whatsapp channel form' do
        get new_channels_whatsapp_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/whatsapp/oauth_authorize' do
      it 'redirects to Meta dialog oauth URL' do
        get oauth_authorize_channels_whatsapp_index_path(locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.facebook.com')
        expect(response.location).to include('dialog/oauth')
      end
    end

    describe 'GET /channels/whatsapp/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_secret).and_return(secret)
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_id).and_return('wa_app_123')
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_whatsapp_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        let(:cb_phone) { "+1 555-#{SecureRandom.random_number(100..999)}-#{SecureRandom.random_number(1000..9999)}" }
        let(:cb_phone_id) { "phone_#{SecureRandom.hex(4)}" }
        let(:cb_waba_id) { "waba_#{SecureRandom.hex(4)}" }

        before do
          allow(Channels::Whatsapp::SignupService).to receive(:call).and_return({
            access_token: 'meta_access_token',
            waba_id: cb_waba_id,
            phone_number_id: cb_phone_id,
            display_phone_number: cb_phone,
            name: 'Techbolic Live Support'
          })
        end

        it 'exchanges the code, creates the channel, and redirects to edit' do
          get callback_channels_whatsapp_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:see_other)
          expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: cb_phone_id) }).to exist
        end
      end
    end

    describe 'POST /channels/whatsapp/callback' do
      let(:cb_phone) { "+1 555-#{SecureRandom.random_number(100..999)}-#{SecureRandom.random_number(1000..9999)}" }
      let(:cb_phone_id) { "phone_#{SecureRandom.hex(4)}" }
      let(:cb_waba_id) { "waba_#{SecureRandom.hex(4)}" }

      before do
        allow(Channels::Whatsapp::SignupService).to receive(:call).with(
          hash_including(
            code: 'valid_auth_code',
            waba_id: cb_waba_id,
            phone_number_id: cb_phone_id,
            account: account
          )
        ).and_return({
          access_token: 'meta_access_token',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id,
          display_phone_number: cb_phone,
          name: 'Techbolic Live Support'
        })
      end

      it 'completes embedded signup and redirects to edit' do
        post callback_channels_whatsapp_index_path(locale: :en), params: {
          code: 'valid_auth_code',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id
        }
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: cb_phone_id) }).to exist
      end

      it 'handles SignupService errors gracefully and redirects to new' do
        allow(Channels::Whatsapp::SignupService).to receive(:call).and_raise(RuntimeError.new('Invalid OAuth Code'))

        post callback_channels_whatsapp_index_path(locale: :en), params: { code: 'bad_code' }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_channels_whatsapp_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('dashboard.whatsapp_channels.callback_error'))
      end

      it 'redirects if channel limit is reached' do
        plan.update!(limits: { 'channels' => 0, 'users' => 100 })

        post callback_channels_whatsapp_index_path(locale: :en), params: {
          code: 'valid_auth_code',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id
        }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'POST /channels/whatsapp (Manual setup)' do
      let(:manual_suffix) { SecureRandom.random_number(1000000..9999999).to_s }
      let(:valid_params) do
        {
          channel_whatsapp: {
            name: 'Manual WhatsApp',
            phone_code: '+1',
            phone_number: "555#{manual_suffix}",
            phone_number_id: "phone_manual_#{manual_suffix}",
            business_account_id: "waba_manual_#{manual_suffix}",
            api_key: 'permanent_token_123'
          }
        }
      end

      it 'creates a new manual WhatsApp channel and redirects to edit' do
        post channels_whatsapp_index_path(locale: :en), params: valid_params
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: "phone_manual_#{manual_suffix}") }).to exist
      end

      it 'handles invalid parameters by redirecting to new form' do
        post channels_whatsapp_index_path(locale: :en), params: {
          channel_whatsapp: { name: '', phone_number: '' }
        }
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(new_channels_whatsapp_path)
      end
    end

    describe 'PATCH /channels/whatsapp/:id' do
      it 'updates channel name' do
        patch channels_whatsapp_path(id: whatsapp_channel.id, locale: :en), params: {
          channel_whatsapp: { name: 'Updated Channel Name' }
        }
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { whatsapp_channel.reload.name }).to eq('Updated Channel Name')
      end
    end

    describe 'DELETE /channels/whatsapp/:id' do
      it 'destroys whatsapp channel' do
        delete channels_whatsapp_path(id: whatsapp_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::Whatsapp.where(id: whatsapp_channel.id) }).not_to exist
      end
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
        get oauth_authorize_channels_instagram_index_path
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.instagram.com/oauth/authorize')
        expect(response.location).to include('client_id=')
        expect(response.location).to include('response_type=code')
        expect(response.location).to include('instagram_business_basic')
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

        it 'updates and reactivates existing channel if already connected' do
          existing = account.with_shard do
            create(:channel_instagram, account: account, instagram_id: 'reconnect_ig_123', status: :disconnected)
          end

          allow(oauth_service).to receive(:exchange_code).and_return({
            access_token: 'ig_reconnected_token',
            expires_at: 60.days.from_now,
            user: { id: 'reconnect_ig_123', username: 'acme_ig', name: 'Acme IG', avatar_url: 'https://example.com/avatar.jpg' }
          })

          get callback_channels_instagram_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:redirect)
          expect(existing.reload.status).to eq('active')
          expect(existing.access_token).to eq('ig_reconnected_token')
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
