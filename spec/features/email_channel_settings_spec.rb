# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email Channel Settings Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, features: { 'channels' => { 'email' => true } }, limits: { 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account, name: 'Email Support Inbox') }
  let(:email_channel) do
    account.with_shard do
      create(:channel_email,
             account: account,
             name: 'Customer Support Email',
             email: "support_#{SecureRandom.hex(4)}@deskbolic-test.com",
             primary_inbox: inbox)
    end
  end

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'editing an email channel' do
    it 'displays the edit form with SMTP and IMAP settings sections' do
      visit edit_channels_email_path(id: email_channel.id, locale: :en)

      expect(page).to have_content('Edit Email Channel')
      expect(page).to have_field('email_channel[name]', with: 'Customer Support Email')
      expect(page).to have_field('email_channel[email]', with: email_channel.email)
      expect(page).to have_content('SMTP Configuration')
      expect(page).to have_content('IMAP Configuration')
      expect(page).to have_css("button[data-action*='testSmtp']")
      expect(page).to have_css("button[data-action*='testImap']")
    end

    it 'allows configuring SMTP and saving without providing an explicit domain' do
      visit edit_channels_email_path(id: email_channel.id, locale: :en)

      check 'email_channel[smtp_enabled]'
      fill_in 'email_channel[smtp_configurations][address]', with: 'smtp.mailservice.com'
      fill_in 'email_channel[smtp_configurations][port]', with: '587'
      fill_in 'email_channel[smtp_configurations][username]', with: email_channel.email
      fill_in 'email_channel[smtp_configurations][password]', with: 'super-secure-pass'
      # Leaving domain blank intentionally to test proper handling

      click_button 'Save Changes'

      expect(page).to have_content('Email channel updated successfully.')

      account.with_shard do
        email_channel.reload
        expect(email_channel.smtp_enabled).to be true
        expect(email_channel.smtp_configurations['address']).to eq('smtp.mailservice.com')
        expect(email_channel.smtp_configurations['domain']).to be_blank
        # Verify model delivery options fallback to email domain without random account domains
        delivery_opts = email_channel.smtp_delivery_options
        expect(delivery_opts[:domain]).to eq(email_channel.email.split('@').last)
      end
    end
  end
end
