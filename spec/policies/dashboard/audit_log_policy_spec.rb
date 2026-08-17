# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AuditLogPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:audit_log) { double('AuditLog') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and feature is enabled' do
      subject { described_class.new(owner_user, audit_log) }

      before do
        allow(account).to receive(:feature_enabled?).with(:audit_logs).and_return(true)
      end

      it 'permits index and revert' do
        expect(subject.index?).to be true
        expect(subject.revert?).to be true
      end
    end

    context 'when audit_logs feature is disabled' do
      subject { described_class.new(owner_user, audit_log) }

      before do
        allow(account).to receive(:feature_enabled?).with(:audit_logs).and_return(false)
      end

      it 'denies actions with failure reason' do
        expect(subject.index?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
      end
    end

    context 'when user lacks permissions' do
      subject { described_class.new(regular_user, audit_log) }

      before do
        allow(account).to receive(:feature_enabled?).with(:audit_logs).and_return(true)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.revert?).to be false
      end
    end
  end
end
