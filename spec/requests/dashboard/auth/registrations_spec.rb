# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Registrations', type: :request do
  around do |example|
    orig = ENV.fetch('DISABLE_REGISTRATION', nil)
    ENV['DISABLE_REGISTRATION'] = 'false'
    example.run
    ENV['DISABLE_REGISTRATION'] = orig
  end

  describe 'GET /users/sign_up' do
    it 'stores ref and currency cookies when params are provided on GET' do
      profile = create(:affiliate_profile)
      get new_user_registration_path, params: { ref: profile.referral_code, currency: 'EUR' }
      expect(response).to have_http_status(:ok)
      expect(cookies[:ref]).to eq(profile.referral_code)
      expect(cookies[:currency]).to eq('EUR')
    end

    it 'renders registration page with early access badge and notice without HTTP basic auth' do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.headers['WWW-Authenticate']).to be_nil
      expect(response.body).to include('Early Access')
      expect(response.body).to include('Welcome to Deskbolic Early Access')
    end

    context 'when DISABLE_REGISTRATION is true' do
      around do |example|
        orig = ENV.fetch('DISABLE_REGISTRATION', nil)
        ENV['DISABLE_REGISTRATION'] = 'true'
        example.run
        ENV['DISABLE_REGISTRATION'] = orig
      end

      it 'redirects to sign in with an alert' do
        get new_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq('Registration is temporarily closed.')
      end
    end
  end

  describe 'POST /users' do
    before do
      get new_user_registration_path
    end

    it 'creates new user account and auto-generates identifier when omitted' do
      post user_registration_path, params: {
        user: {
          first_name: 'Jane',
          last_name: 'Doe',
          email: "jane_doe_#{SecureRandom.hex(4)}@example.com",
          password: 'password123'
        },
        account_name: 'Jane Support Org',
        country: 'US',
        currency: 'USD',
        shard_key: 'de',
        account_locale: 'en'
      }
      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      account = Account.find_by(name: 'Jane Support Org')
      expect(account).to be_present
      expect(account.identifier).to eq('jane-support-org')
    end

    it 'creates new user account with explicit custom account_identifier' do
      custom_slug = "custom-slug-#{SecureRandom.hex(3)}"
      post user_registration_path, params: {
        user: {
          first_name: 'John',
          last_name: 'Custom',
          email: "custom_#{SecureRandom.hex(4)}@example.com",
          password: 'password123'
        },
        account_name: 'Common Company Name',
        account_identifier: custom_slug,
        country: 'US',
        currency: 'USD',
        shard_key: 'de',
        account_locale: 'en'
      }
      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      account = Account.find_by(identifier: custom_slug)
      expect(account).to be_present
      expect(account.name).to eq('Common Company Name')
      expect(account.identifier).to eq(custom_slug)
    end

    it 'creates affiliate referral when ref param is present' do
      profile = create(:affiliate_profile)
      email = "referred_user_#{SecureRandom.hex(4)}@example.com"

      expect do
        post user_registration_path, params: {
          user: {
            first_name: 'Referred',
            last_name: 'Lead',
            email: email,
            password: 'password123'
          },
          account_name: 'Referred Organization',
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en',
          ref: profile.referral_code
        }
      end.to change(Affiliate::Referral, :count).by(1)

      expect(response).to have_http_status(:redirect).or have_http_status(:see_other)
      referral = Affiliate::Referral.last
      expect(referral.profile).to eq(profile)
      expect(referral.account.name).to eq('Referred Organization')
    end

    it 'creates affiliate referral when ref is present in cookie' do
      profile = create(:affiliate_profile)
      cookies[:ref] = profile.referral_code
      email = "cookie_user_#{SecureRandom.hex(4)}@example.com"

      expect do
        post user_registration_path, params: {
          user: {
            first_name: 'Cookie',
            last_name: 'Lead',
            email: email,
            password: 'password123'
          },
          account_name: 'Cookie Organization',
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en'
        }
      end.to change(Affiliate::Referral, :count).by(1)

      referral = Affiliate::Referral.last
      expect(referral.profile).to eq(profile)
    end

    it 'does not create referral when user email matches affiliate profile user email (self-referral prevention)' do
      affiliate_user = create(:user, email: 'affiliate_owner@example.com')
      profile = create(:affiliate_profile, user: affiliate_user)

      expect do
        post user_registration_path, params: {
          user: {
            first_name: 'Self',
            last_name: 'Refer',
            email: 'affiliate_owner@example.com',
            password: 'password123'
          },
          account_name: 'Self Org',
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en',
          ref: profile.referral_code
        }
      end.not_to change(Affiliate::Referral, :count)
    end

    context 'with invalid identifier' do
      it 'fails registration when custom identifier is already taken' do
        create(:account, identifier: 'taken-identifier')

        post user_registration_path, params: {
          user: {
            first_name: 'John',
            last_name: 'Custom',
            email: "new_#{SecureRandom.hex(4)}@example.com",
            password: 'password123'
          },
          account_name: 'Custom Org',
          account_identifier: 'taken-identifier',
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en'
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'fails registration when custom identifier is reserved' do
        post user_registration_path, params: {
          user: {
            first_name: 'John',
            last_name: 'Custom',
            email: "new_#{SecureRandom.hex(4)}@example.com",
            password: 'password123'
          },
          account_name: 'Admin Org',
          account_identifier: 'admin',
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en'
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'silently rejects spam when honeypot field is filled' do
        expect {
          post user_registration_path, params: {
            user: {
              first_name: 'Bot',
              last_name: 'Spammer',
              email: "bot_#{SecureRandom.hex(4)}@example.com",
              password: 'password123',
              gift_vcode: 'bot_payload'
            },
            gift_vcode: 'bot_payload',
            account_name: 'Spam Corp',
            country: 'US',
            currency: 'USD',
            shard_key: 'de',
            account_locale: 'en'
          }
        }.not_to change { User.count }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
