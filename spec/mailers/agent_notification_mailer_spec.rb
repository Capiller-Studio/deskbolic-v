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
