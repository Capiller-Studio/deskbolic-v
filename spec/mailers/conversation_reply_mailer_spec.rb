# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationReplyMailer, type: :mailer do
  let(:account) { create(:account, identifier: 'acme') }
  let(:channel) { create(:channel_email, account: account, email: "support-#{SecureRandom.hex(4)}@acme.com") }
  let(:inbox) { create(:inbox, account: account, channel: channel, name: 'Support Inbox') }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com', name: 'John Doe') }
  let(:user) { create(:user, name: 'Agent Smith', display_name: 'Agent Smith') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, title: 'Help with Order') }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: user, content: 'We received your order!') }

  describe '#reply' do
    it 'renders reply email to customer' do
      mail = described_class.reply(conversation, message, channel)
      expect(mail.to).to eq([ 'customer@example.com' ])
      expect(mail.subject).to include('Help with Order')
      expect(mail.from).to include('support@helpbolic.com')
      expect(mail[:from].display_names).to eq([ "Agent Smith from #{account.name}" ])
      expect(mail.reply_to.first).to match(/reply\+#{conversation.identifier}@/)
    end

    it 'uses channel email when custom smtp is enabled' do
      allow(channel).to receive(:smtp_enabled?).and_return(true)
      mail = described_class.reply(conversation, message, channel)
      expect(mail.from).to include(channel.email)
    end

    context 'when replying to contact form conversation' do
      let(:contact_form) { create(:channel_contact_form, account: account, outbound_channel: outbound_email) }
      let(:inbox) { create(:inbox, account: account, channel: contact_form, name: 'Contact Form Inbox') }

      context 'with outbound email channel configured' do
        let(:outbound_email) { create(:channel_email, account: account, email: "custom-#{SecureRandom.hex(4)}@acme.com") }

        it 'uses outbound email channel' do
          mail = described_class.reply(conversation, message)
          expect(mail.to).to eq([ 'customer@example.com' ])
          expect(mail.reply_to.first).to match(/reply\+#{conversation.identifier}@/)
        end
      end

      context 'without outbound email channel configured' do
        let(:outbound_email) { nil }

        it 'defaults to system relay and account helpbolic reply-to domain' do
          mail = described_class.reply(conversation, message)
          expect(mail.to).to eq([ 'customer@example.com' ])
          expect(mail.from).to include('support@helpbolic.com')
          expect(mail.reply_to).to eq([ "reply+#{conversation.identifier}@acme.helpbolic.com" ])
        end
      end
    end
  end
end
