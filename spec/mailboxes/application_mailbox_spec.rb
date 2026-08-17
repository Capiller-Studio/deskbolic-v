# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailbox, type: :mailbox do
  let(:account) { create(:account) }

  describe 'routing helpers' do
    describe '.spam_or_auto_reply?' do
      it 'detects auto-submitted emails' do
        mail = Mail.new(headers: { 'Auto-Submitted' => 'auto-replied' })
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.spam_or_auto_reply?(inbound)).to be true
      end

      it 'detects mailer-daemon emails' do
        mail = Mail.new(from: 'mailer-daemon@google.com')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.spam_or_auto_reply?(inbound)).to be true
      end

      it 'returns false for regular customer emails' do
        mail = Mail.new(from: 'customer@gmail.com')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.spam_or_auto_reply?(inbound)).to be false
      end
    end

    describe '.forwarding_confirmation?' do
      it 'detects gmail forwarding confirmation' do
        mail = Mail.new(from: 'forwarding-noreply@google.com')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.forwarding_confirmation?(inbound)).to be true
      end

      it 'detects forwarding confirmation in subject' do
        mail = Mail.new(subject: 'Forwarding Confirmation for support@company.com')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.forwarding_confirmation?(inbound)).to be true
      end
    end

    describe '.reply_email?' do
      it 'detects reply+uuid pattern in to address' do
        mail = Mail.new(to: 'reply+conv-123@acme.helpbolic.com')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.reply_email?(inbound)).to be true
      end

      it 'detects In-Reply-To header' do
        mail = Mail.new(in_reply_to: '<msg-123@helpbolic.com>')
        inbound = double('InboundEmail', mail: mail)
        expect(described_class.reply_email?(inbound)).to be true
      end
    end
  end
end
