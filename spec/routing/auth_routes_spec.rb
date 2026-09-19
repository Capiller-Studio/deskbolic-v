# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication & Devise Routing', type: :routing do
  describe 'OmniAuth callbacks routing (unlocalized root level)' do
    it 'routes Google OAuth authorize endpoint' do
      expect(post: '/users/auth/google_oauth2').to route_to(
        controller: 'dashboard/omniauth_callbacks',
        action: 'passthru'
      )
    end

    it 'routes Google OAuth callback endpoint' do
      expect(get: '/users/auth/google_oauth2/callback').to route_to(
        controller: 'dashboard/omniauth_callbacks',
        action: 'google_oauth2'
      )
    end

    it 'routes Facebook OAuth authorize endpoint' do
      expect(post: '/users/auth/facebook').to route_to(
        controller: 'dashboard/omniauth_callbacks',
        action: 'passthru'
      )
    end

    it 'routes Facebook OAuth callback endpoint' do
      expect(get: '/users/auth/facebook/callback').to route_to(
        controller: 'dashboard/omniauth_callbacks',
        action: 'facebook'
      )
    end
  end

  describe 'User sessions and registrations routing (with and without locale)' do
    it 'routes /login without locale' do
      expect(get: '/login').to route_to(
        controller: 'dashboard/sessions',
        action: 'new'
      )
    end

    it 'routes /en/login with locale' do
      expect(get: '/en/login').to route_to(
        controller: 'dashboard/sessions',
        action: 'new',
        locale: 'en'
      )
    end

    it 'routes /es/login with locale' do
      expect(get: '/es/login').to route_to(
        controller: 'dashboard/sessions',
        action: 'new',
        locale: 'es'
      )
    end

    it 'routes /logout' do
      expect(delete: '/logout').to route_to(
        controller: 'dashboard/sessions',
        action: 'destroy'
      )
    end

    it 'routes /register' do
      expect(get: '/register').to route_to(
        controller: 'dashboard/registrations',
        action: 'new'
      )
    end
  end

  describe 'Enterprise SSO and SAML routes' do
    it 'routes /auth/domain_lookup' do
      expect(get: '/auth/domain_lookup').to route_to(
        controller: 'auth/domain_lookups',
        action: 'show'
      )
    end

    it 'routes /auth/saml/metadata' do
      expect(get: '/auth/saml/metadata').to route_to(
        controller: 'auth/saml/sessions',
        action: 'metadata'
      )
    end

    it 'routes /auth/saml/initiate' do
      expect(get: '/auth/saml/initiate').to route_to(
        controller: 'auth/saml/sessions',
        action: 'initiate'
      )
    end

    it 'routes /auth/saml/consume' do
      expect(post: '/auth/saml/consume').to route_to(
        controller: 'auth/saml/sessions',
        action: 'consume'
      )
    end
  end
end
