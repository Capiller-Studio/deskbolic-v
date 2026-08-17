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
    it 'renders registration page' do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users' do
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
  end
end
