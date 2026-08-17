# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemMailer, type: :mailer do
  let(:account) { create(:account, email: 'owner@company.com') }

  describe '#test_template' do
    it 'renders test template email' do
      mail = described_class.test_template(to: 'test@example.com', subject: 'Test Subject', body: '<p>Hello</p>')
      expect(mail.to).to eq([ 'test@example.com' ])
      expect(mail.subject).to eq('Test Subject')
      expect(mail.body.encoded).to include('Hello')
    end
  end

  describe '#custom_email' do
    it 'renders custom email' do
      mail = described_class.custom_email(to: 'user@example.com', subject: 'Custom Subject', body: '<p>Custom Body</p>')
      expect(mail.to).to eq([ 'user@example.com' ])
      expect(mail.subject).to eq('Custom Subject')
    end
  end

  describe '#forward_email_verification' do
    let(:email_channel) { create(:channel_email, account: account, email: "support-#{SecureRandom.hex(4)}@company.com", forward_email_token: 'XYZ123TOKEN') }

    it 'renders forwarding verification email' do
      mail = described_class.forward_email_verification(email_channel)
      expect(mail.to).to eq([ email_channel.email ])
      expect(mail.subject).to include('XYZ123TOKEN')
    end
  end

  describe '#subscription_reminder' do
    it 'renders subscription reminder email' do
      mail = described_class.subscription_reminder(account)
      expect(mail.to).to eq([ 'owner@company.com' ])
    end
  end
end
