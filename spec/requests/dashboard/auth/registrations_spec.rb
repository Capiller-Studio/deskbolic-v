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
  end

  describe 'POST /users' do
    before do
      get new_user_registration_path
    end

    it 'creates new user account' do
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
  end
end
