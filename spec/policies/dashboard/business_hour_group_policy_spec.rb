# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::BusinessHourGroupPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:business_hour_group) { create(:business_hour_group, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and feature is enabled' do
      subject { described_class.new(owner_user, business_hour_group) }

      before do
        allow(account).to receive(:feature_enabled?).with(:business_hours).and_return(true)
      end

      it 'permits index, show, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when business_hours feature is disabled' do
      subject { described_class.new(owner_user, business_hour_group) }

      before do
        allow(account).to receive(:feature_enabled?).with(:business_hours).and_return(false)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
      end
    end

    context 'when limit is reached' do
      subject { described_class.new(owner_user, business_hour_group) }

      before do
        allow(account).to receive(:feature_enabled?).with(:business_hours).and_return(true)
        allow(account).to receive(:limit_reached?).with(:business_hour_groups, strict: true).and_return(true)
      end

      it 'denies create' do
        expect(subject.create?).to be false
        expect(subject.authorization_failure_reason).to eq(:limit_reached)
      end
    end
  end
end
