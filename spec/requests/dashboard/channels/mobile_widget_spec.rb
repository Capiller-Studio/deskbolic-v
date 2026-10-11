# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels::MobileWidget', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'roles' => true, 'channels' => { 'mobile_widget' => true } },
      limits: { 'channels' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:mobile_widget_channel) do
    account.with_shard do
      channel = create(:channel_mobile_widget, account: account, name: 'Customer Mobile App')
      create(:inbox, channel: channel, account: account, primary_inbox: true)
      channel
    end
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /channels/mobile_widget' do
    it 'renders the mobile widget channels index' do
      mobile_widget_channel
      get channels_mobile_widget_index_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Customer Mobile App')
    end
  end

  describe 'GET /channels/mobile_widget/:id' do
    it 'renders the show page with device statistics' do
      account.with_shard do
        customer = create(:customer, account: account)
        customer_inbox = create(:customer_inbox, inbox: mobile_widget_channel.primary_inbox, customer: customer)
        create(:customer_device, account: account, inbox: mobile_widget_channel.primary_inbox, customer: customer, customer_inbox: customer_inbox, push_token: 'test_token_1', platform: :ios)
      end

      get channels_mobile_widget_path(mobile_widget_channel, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(mobile_widget_channel.name)
    end
  end

  describe 'GET /channels/mobile_widget/new' do
    it 'renders the new mobile widget channel form' do
      get new_channels_mobile_widget_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('mobile_widget_channel[name]')
    end
  end

  describe 'POST /channels/mobile_widget' do
    context 'with valid parameters' do
      it 'creates a mobile widget channel with primary inbox and identifier' do
        unique_name = "iOS App #{SecureRandom.hex(4)}"
        expect {
          post channels_mobile_widget_index_path(locale: :en), params: {
            mobile_widget_channel: {
              name: unique_name,
              default_locale: 'en',
              anonymous_allowed: '1',
              push_enabled: '1'
            }
          }
        }.to change {
          account.with_shard { Channel::MobileWidget.count }
        }.by(1)

        created_channel = account.with_shard { Channel::MobileWidget.find_by(name: unique_name) }
        expect(created_channel.name).to eq(unique_name)
        expect(created_channel.identifier).to start_with('dbk_app_')
        expect(created_channel.secret).to be_present
        expect(created_channel.anonymous_allowed?).to be true
        expect(created_channel.push_enabled?).to be true
        expect(response).to redirect_to(edit_channels_mobile_widget_path(created_channel))
      end
    end

    context 'with invalid parameters' do
      it 'fails validation and renders new form with 422 status' do
        expect {
          post channels_mobile_widget_index_path(locale: :en), params: {
            mobile_widget_channel: {
              name: '',
              default_locale: 'en'
            }
          }
        }.not_to change {
          account.with_shard { Channel::MobileWidget.count }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when channel limit is reached' do
      it 'redirects to billing with alert' do
        allow_any_instance_of(Account).to receive(:within_limit?).with(:channels).and_return(false)

        post channels_mobile_widget_index_path(locale: :en), params: {
          mobile_widget_channel: {
            name: 'Over Limit App'
          }
        }

        expect(response).to redirect_to(dashboard_billing_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'with fallback channel from another account' do
      let(:other_account) { create(:account) }
      let(:foreign_email_channel) do
        other_account.with_shard do
          create(:channel_email, account: other_account)
        end
      end

      it 'rejects fallback channel belonging to different account' do
        expect {
          post channels_mobile_widget_index_path(locale: :en), params: {
            mobile_widget_channel: {
              name: 'Invalid Fallback App',
              fallback_channel_id: foreign_email_channel.id,
              fallback_channel_type: 'Channel::Email'
            }
          }
        }.not_to change {
          account.with_shard { Channel::MobileWidget.count }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /channels/mobile_widget/:id/edit' do
    it 'renders the edit mobile widget channel form' do
      get edit_channels_mobile_widget_path(mobile_widget_channel, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(mobile_widget_channel.name)
      expect(response.body).to include(mobile_widget_channel.identifier)
    end
  end

  describe 'PATCH /channels/mobile_widget/:id' do
    it 'updates mobile widget channel settings' do
      patch channels_mobile_widget_path(mobile_widget_channel, locale: :en), params: {
        mobile_widget_channel: {
          name: 'Updated App Name',
          ios_bundle_id: 'com.deskbolic.app',
          apns_key_id: 'ABC123DEFG',
          apns_team_id: 'TEAM123456',
          push_enabled: '1'
        }
      }

      expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
      mobile_widget_channel.reload
      expect(mobile_widget_channel.name).to eq('Updated App Name')
      expect(mobile_widget_channel.ios_bundle_id).to eq('com.deskbolic.app')
      expect(mobile_widget_channel.apns_key_id).to eq('ABC123DEFG')
    end

    it 'renders edit with 422 when params are invalid' do
      patch channels_mobile_widget_path(mobile_widget_channel, locale: :en), params: {
        mobile_widget_channel: {
          name: ''
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /channels/mobile_widget/:id/regenerate_secret' do
    it 'rotates the secret key' do
      old_secret = mobile_widget_channel.secret

      post regenerate_secret_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

      expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel, anchor: 'identity'))
      mobile_widget_channel.reload
      expect(mobile_widget_channel.secret).not_to eq(old_secret)
    end
  end

  describe 'POST /channels/mobile_widget/:id/test_push' do
    context 'when no devices are registered' do
      it 'redirects back with alert that no devices exist' do
        post test_push_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

        expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
        expect(flash[:alert]).to include(I18n.t('dashboard.mobile_widget_channels.no_devices'))
      end
    end

    context 'with an active APNs device' do
      let!(:apns_device) do
        account.with_shard do
          cust = create(:customer, account: account)
          ci = create(:customer_inbox, inbox: mobile_widget_channel.primary_inbox, customer: cust)
          create(:customer_device, account: account, inbox: mobile_widget_channel.primary_inbox, customer: cust, customer_inbox: ci, push_token: 'apns_tok_1', platform: :ios, push_provider: :apns)
        end
      end

      it 'dispatches APNs test notification and notifies success on true' do
        expect(PushNotifications::ApnsSender).to receive(:call).and_return(true)

        post test_push_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

        expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
        expect(flash[:notice]).to include(I18n.t('dashboard.mobile_widget_channels.test_push_success'))
      end

      it 'handles APNs test delivery failure and alerts user' do
        expect(PushNotifications::ApnsSender).to receive(:call).and_return(false)

        post test_push_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

        expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
        expect(flash[:alert]).to include(I18n.t('dashboard.mobile_widget_channels.test_push_failed'))
      end
    end

    context 'with an active FCM device' do
      let!(:fcm_device) do
        account.with_shard do
          cust = create(:customer, account: account)
          ci = create(:customer_inbox, inbox: mobile_widget_channel.primary_inbox, customer: cust)
          create(:customer_device, account: account, inbox: mobile_widget_channel.primary_inbox, customer: cust, customer_inbox: ci, push_token: 'fcm_tok_1', platform: :android, push_provider: :fcm)
        end
      end

      it 'dispatches FCM test notification and notifies success on true' do
        expect(PushNotifications::FcmSender).to receive(:call).and_return(true)

        post test_push_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

        expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
        expect(flash[:notice]).to include(I18n.t('dashboard.mobile_widget_channels.test_push_success'))
      end

      it 'handles FCM test delivery failure and alerts user' do
        expect(PushNotifications::FcmSender).to receive(:call).and_return(false)

        post test_push_channels_mobile_widget_path(mobile_widget_channel, locale: :en)

        expect(response).to redirect_to(edit_channels_mobile_widget_path(mobile_widget_channel))
        expect(flash[:alert]).to include(I18n.t('dashboard.mobile_widget_channels.test_push_failed'))
      end
    end
  end

  describe 'DELETE /channels/mobile_widget/:id' do
    it 'destroys the mobile widget channel' do
      channel_to_destroy = mobile_widget_channel

      expect {
        delete channels_mobile_widget_path(channel_to_destroy, locale: :en)
      }.to change {
        account.with_shard { Channel::MobileWidget.count }
      }.by(-1)

      expect(response).to redirect_to(channels_mobile_widget_index_path)
    end
  end
end
