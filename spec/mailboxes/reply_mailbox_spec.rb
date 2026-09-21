# frozen_string_literal: true

require 'rails_helper'
require 'action_mailbox/test_helper'

RSpec.describe ReplyMailbox, type: :mailbox do
  include ActionMailbox::TestHelper
  let(:account) { create(:account, identifier: 'techbolic') }
  let(:contact_form) { create(:channel_contact_form, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: contact_form, name: 'Website Support Form') }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com', name: 'John Doe') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, title: 'Testing the contact form') }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }

  describe 'processing inbound replies' do
    it 'finds conversation and account case-insensitively from reply+ tag and domain' do
      inbound_email = receive_inbound_email_from_mail(
        to: "reply+#{conversation.identifier}@techbolic.helpbolic.com",
        from: 'customer@example.com',
        subject: 'Re: Testing the contact form',
        body: 'Here is the additional info requested.'
      )

      expect(inbound_email).to have_been_delivered
      account.with_shard do
        new_message = conversation.messages.last
        expect(new_message).to be_present
        expect(new_message.content).to include('Here is the additional info requested.')
        expect(new_message.sender).to eq(customer)
      end
    end

    it 'processes reply to contact form conversation without requiring an email channel' do
      inbound_email = receive_inbound_email_from_mail(
        to: "reply+#{conversation.identifier}@techbolic.helpbolic.com",
        from: 'customer@example.com',
        subject: 'Re: Testing the contact form',
        body: 'Reply to contact form without email channel'
      )

      expect(inbound_email).not_to have_bounced
      expect(inbound_email).to have_been_delivered
    end

    it 'matches conversation via In-Reply-To header when replying to an email channel' do
      email_channel = create(:channel_email, account: account, email: "help-#{SecureRandom.hex(4)}@techbolic.com")
      email_inbox = create(:inbox, account: account, channel: email_channel)
      email_conv = create(:conversation, account: account, inbox: email_inbox)
      agent = create(:user, name: 'Agent Smith')
      agent_message = create(:message, account: account, conversation: email_conv, sender: agent, content: 'Agent response')

      inbound_email = receive_inbound_email_from_mail(
        to: email_channel.email,
        from: 'customer@example.com',
        subject: 'Re: Help request',
        in_reply_to: "<#{agent_message.id}@helpbolic.com>",
        body: 'Replying to specific message ID'
      )

      expect(inbound_email).to have_been_delivered
      account.with_shard do
        new_message = email_conv.messages.reload.last
        expect(new_message.content).to include('Replying to specific message ID')
      end
    end

    it 'bounces if conversation cannot be found and no email channel matches' do
      inbound_email = receive_inbound_email_from_mail(
        to: 'reply+NONEXISTENT999@techbolic.helpbolic.com',
        from: 'unknown@example.com',
        subject: 'Random reply',
        body: 'No conversation'
      )

      expect(inbound_email).to have_bounced
    end
  end
end
