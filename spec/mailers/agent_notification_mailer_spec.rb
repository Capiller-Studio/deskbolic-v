# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentNotificationMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'agent@example.com', locale: 'en') }
  let(:conversation) { create(:conversation, account: account) }
  let(:notification) do
    create(:notification, account: account, user: user, resource: conversation, event: 'conversation_assigned')
  end

  describe '#notify' do
    it 'sends notification email to user' do
      mail = described_class.notify(notification)
      expect(mail.to).to eq([ 'agent@example.com' ])
      expect(mail.subject).to be_present
    end

    it 'renders limit_approaching notification email with billing link' do
      limit_notif = create(:notification, account: account, user: user, resource: account, event: 'limit_approaching')
      mail = described_class.notify(limit_notif)
      expect(mail.to).to eq([ 'agent@example.com' ])
      expect(mail.body.encoded).to include('/settings/billing')
    end

    it 'renders limit_reached notification email with billing link' do
      limit_notif = create(:notification, account: account, user: user, resource: account, event: 'limit_reached')
      mail = described_class.notify(limit_notif)
      expect(mail.to).to eq([ 'agent@example.com' ])
      expect(mail.body.encoded).to include('/settings/billing')
    end
  end

  describe '#conversation_assigned' do
    it 'renders conversation assigned email' do
      mail = described_class.conversation_assigned(notification)
      expect(mail.to).to eq([ 'agent@example.com' ])
      expect(mail.subject).to include(conversation.identifier)
    end
  end

  describe '#sla_breached' do
    it 'renders sla breached email' do
      mail = described_class.sla_breached(notification)
      expect(mail.to).to eq([ 'agent@example.com' ])
      expect(mail.subject).to include(conversation.identifier)
    end
  end
end
