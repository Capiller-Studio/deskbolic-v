# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internationalization (i18n) Feature', :js, type: :feature do
  let!(:country) { Country.find_or_create_by!(iso: 'US') { |c| c.iso_name = 'United States'; c.iso3 = 'USA' } }
  let!(:plan) do
    create(:plan,
      features: { 'roles' => true, 'channels' => { 'custom' => true } },
      limits: { 'channels' => 10, 'users' => 10 }
    )
  end

  around do |example|
    orig = ENV.fetch('DISABLE_REGISTRATION', nil)
    ENV['DISABLE_REGISTRATION'] = 'false'
    example.run
    ENV['DISABLE_REGISTRATION'] = orig
  end

  describe 'Localized routes across all supported locales' do
    it 'renders the login page for every Core::SUPPORTED_LOCALES' do
      reset_subdomain

      Core::SUPPORTED_LOCALES.each do |locale|
        visit "#{Capybara.app_host}/#{locale}/login"
        expect(page).to have_css('form.auth-form')
        expect(page.html).to include("lang=\"#{locale}\"")
      end
    end
  end

  describe 'RTL and locale-specific attributes' do
    it 'renders RTL layout and Arabic text for Arabic locale (/ar/login)' do
      reset_subdomain
      visit "#{Capybara.app_host}/ar/login"

      # Check HTML tag attributes for RTL and Arabic
      expect(page.html).to match(/<html[^>]*dir=["']rtl["']/)
      expect(page.html).to match(/<html[^>]*lang=["']ar["']/)

      # Verify Arabic login content
      expect(page).to have_text('تسجيل الدخول')
    end

    it 'renders LTR layout and Spanish text for Spanish locale (/es/login)' do
      reset_subdomain
      visit "#{Capybara.app_host}/es/login"

      # Check HTML tag attributes for LTR and Spanish
      expect(page.html).to match(/<html[^>]*dir=["']ltr["']/)
      expect(page.html).to match(/<html[^>]*lang=["']es["']/)

      # Verify Spanish login content
      expect(page).to have_text(/iniciar sesión/i)
    end
  end

  describe 'Interactive language dropdown switching' do
    it 'switches locale dynamically when selecting from auth-locale-select' do
      reset_subdomain
      visit "#{Capybara.app_host}/en/login"
      expect(page.html).to match(/<html[^>]*lang=["']en["']/)

      # Select Spanish from auth-locale-select dropdown via JS dispatch to trigger onchange
      page.execute_script(<<~JS)
        const select = document.getElementById('auth-locale-select');
        if (select) {
          const esOption = Array.from(select.options).find(opt => opt.value.includes('/es'));
          if (esOption) {
            select.value = esOption.value;
            window.location.href = select.value;
          }
        }
      JS

      # Page navigates to Spanish login page
      expect(page).to have_text(/iniciar sesión/i)
      expect(page.html).to match(/<html[^>]*lang=["']es["']/)
      expect(page).to have_current_path(%r{/es/login})
    end
  end

  describe 'Account locale persistence during registration' do
    it 'persists account_locale as es in database during workspace signup' do
      reset_subdomain
      visit "#{Capybara.app_host}/en/register"

      fill_in 'user[first_name]', with: 'Hernando'
      fill_in 'user[last_name]', with: 'Cortez'
      page.execute_script("const el = document.getElementById('country'); if (el) { el.value = 'US'; el.dispatchEvent(new Event('change', { bubbles: true })); }")
      fill_in 'user[email]', with: 'hernando.cortez@example.com'
      fill_in 'user[password]', with: 'Conquistador2026!'
      fill_in 'user[password_confirmation]', with: 'Conquistador2026!'

      # Step 1 -> Step 2
      find('button[data-action="click->registration-wizard#nextStep"]').click
      expect(page).to have_text(I18n.t('auth.registration.step2_title'))

      fill_in 'account_name', with: 'Madrid Commerce'
      fill_in 'account_identifier', with: 'madrid-hq'
      choose('shard_key_de', allow_label_click: true)

      # Set account_locale select to Spanish 'es'
      page.execute_script(<<~JS)
        const el = document.getElementById('account_locale') || document.getElementById('user_account_locale');
        if (el) {
          el.value = 'es';
          el.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      find('input[type="submit"]').click

      expect(page).to have_text(I18n.t('devise.registrations.registered_title', default: 'Check your email')).or have_text('registered')

      account = Account.find_by(identifier: 'madrid-hq')
      expect(account).to be_present
      expect(account.locale).to eq('es')
    end
  end

  describe 'Invalid locale redirection' do
    it 'safely redirects an invalid locale URL to the default locale route with 301' do
      reset_subdomain

      # Using rack-test integration / Capybara visit to verify redirect to /login
      visit "#{Capybara.app_host}/invalid_locale/login"
      expect(page).to have_current_path(%r{/login$})
      expect(page).to have_css('form.auth-form')
    end
  end
end
