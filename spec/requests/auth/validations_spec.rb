# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth::Validations', type: :request do
  describe 'GET /auth/check_email' do
    it 'returns valid for an unused email' do
      get '/auth/check_email', params: { email: 'available@example.com' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be true
      expect(json['exists']).to be false
    end

    it 'returns invalid/exists for an already registered email' do
      create(:user, email: 'registered@example.com')
      get '/auth/check_email', params: { email: 'registered@example.com' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['exists']).to be true
    end

    it 'matches email case-insensitively' do
      create(:user, email: 'case_sensitive_test@example.com')
      get '/auth/check_email', params: { email: 'CASE_SENSITIVE_TEST@EXAMPLE.COM' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['exists']).to be true
    end

    it 'returns invalid for a blank email' do
      get '/auth/check_email', params: { email: '' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to be_present
    end
  end

  describe 'GET /auth/check_identifier' do
    it 'returns valid for an available identifier' do
      get '/auth/check_identifier', params: { identifier: 'acme-corp' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be true
      expect(json['slug']).to eq('acme-corp')
    end

    it 'normalizes spaces, uppercase letters, and special characters into slug format' do
      get '/auth/check_identifier', params: { identifier: 'Acme Support Desk!' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be true
      expect(json['slug']).to eq('acme-support-desk')
    end

    it 'returns invalid for a reserved identifier' do
      get '/auth/check_identifier', params: { identifier: 'admin' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('reserved word')
    end

    it 'returns invalid for an already taken identifier' do
      create(:account, identifier: 'taken-slug')
      get '/auth/check_identifier', params: { identifier: 'taken-slug' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('already taken')
    end

    it 'returns invalid for a blank identifier' do
      get '/auth/check_identifier', params: { identifier: '' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('required')
    end

    it 'returns invalid for an identifier that converts to empty slug' do
      get '/auth/check_identifier', params: { identifier: '---$$$---' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('required')
    end

    it 'returns invalid for an identifier shorter than 3 characters' do
      get '/auth/check_identifier', params: { identifier: 'xy' }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('at least 3 characters')
    end

    it 'returns invalid for an identifier longer than 63 characters' do
      get '/auth/check_identifier', params: { identifier: 'a' * 64 }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['valid']).to be false
      expect(json['error']).to include('cannot exceed 63 characters')
    end
  end
end
