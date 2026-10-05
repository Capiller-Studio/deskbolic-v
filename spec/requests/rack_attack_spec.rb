# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack Rate Limiting', type: :request do
  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.reset!
    Rack::Attack.cache.store = original_store
  end

  describe 'POST / (registration throttling)' do
    it 'throttles registrations by IP after 5 attempts' do
      orig = ENV.fetch('DISABLE_REGISTRATION', nil)
      ENV['DISABLE_REGISTRATION'] = 'false'

      5.times do
        post user_registration_path, params: {
          user: {
            first_name: 'John',
            last_name: 'Doe',
            email: "john_#{SecureRandom.hex(4)}@example.com",
            password: 'password123'
          },
          account_name: "Org #{SecureRandom.hex(3)}",
          country: 'US',
          currency: 'USD',
          shard_key: 'de',
          account_locale: 'en'
        }
        expect(response.status).not_to eq(429)
      end

      # 6th request should be throttled
      post user_registration_path, params: {
        user: {
          first_name: 'John',
          last_name: 'Doe',
          email: "john_#{SecureRandom.hex(4)}@example.com",
          password: 'password123'
        },
        account_name: "Org #{SecureRandom.hex(3)}",
        country: 'US',
        currency: 'USD',
        shard_key: 'de',
        account_locale: 'en'
      }
      expect(response.status).to eq(429)

      ENV['DISABLE_REGISTRATION'] = orig
    end
  end

  describe 'POST /login (login throttling)' do
    it 'throttles login attempts by IP after 20 attempts' do
      20.times do |i|
        post user_session_path, params: {
          user: { email: "wrong_#{i}@example.com", password: 'wrong' }
        }
        expect(response.status).not_to eq(429)
      end

      post user_session_path, params: {
        user: { email: 'wrong_21@example.com', password: 'wrong' }
      }
      expect(response.status).to eq(429)
    end
  end

  describe 'POST /password (password reset throttling)' do
    it 'throttles password reset requests by IP after 3 attempts' do
      3.times do
        post user_password_path, params: {
          user: { email: 'user@example.com' }
        }
        expect(response.status).not_to eq(429)
      end

      post user_password_path, params: {
        user: { email: 'user@example.com' }
      }
      expect(response.status).to eq(429)
    end
  end
end
