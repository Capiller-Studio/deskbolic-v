# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard Channel Specific Policies' do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:channel_record) { double('ChannelRecord') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe Dashboard::EmailChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.email').and_return(true) }

      it 'permits all actions' do
        expect(subject.index?).to be true
        expect(subject.new?).to be true
        expect(subject.create?).to be true
        expect(subject.edit?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
        expect(subject.test_smtp?).to be true
        expect(subject.test_imap?).to be true
        expect(subject.verify_forwarding?).to be true
      end
    end

    context 'when feature is disabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.email').and_return(false) }

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end

  describe Dashboard::ContactFormChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.contact_form').and_return(true) }

      it 'permits all actions' do
        expect(subject.index?).to be true
        expect(subject.new?).to be true
        expect(subject.create?).to be true
        expect(subject.edit?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when feature is disabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.contact_form').and_return(false) }

      it 'denies all actions' do
        expect(subject.index?).to be false
        expect(subject.new?).to be false
        expect(subject.create?).to be false
        expect(subject.edit?).to be false
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end

  describe Dashboard::CustomChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.custom').and_return(true) }

      it 'permits all actions including webhook tests' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
        expect(subject.test_outgoing_webhook?).to be true
        expect(subject.test_incoming_webhook?).to be true
      end
    end
  end

  describe Dashboard::FacebookChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.facebook').and_return(true) }

      it 'permits all actions including callback and reconnect' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.callback?).to be true
        expect(subject.reconnect?).to be true
      end
    end
  end

  describe Dashboard::InstagramChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.instagram').and_return(true) }

      it 'permits oauth_authorize and callback' do
        expect(subject.index?).to be true
        expect(subject.oauth_authorize?).to be true
        expect(subject.callback?).to be true
      end
    end
  end

  describe Dashboard::WebWidgetChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.web_widget').and_return(true) }

      it 'permits all actions' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end
  end

  describe Dashboard::WhatsappChannelPolicy do
    subject { described_class.new(owner_user, channel_record) }

    context 'when feature is enabled' do
      before { allow(account).to receive(:feature_enabled?).with('channels.whatsapp').and_return(true) }

      it 'permits callback and reconnect' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.callback?).to be true
        expect(subject.reconnect?).to be true
      end
    end
  end
end
