# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AssignmentPolicyPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and feature is enabled' do
      subject { described_class.new(owner_user, assignment_policy) }

      before do
        allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(true)
      end

      it 'permits index, show, create, update, destroy, toggle, reorder' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
        expect(subject.toggle?).to be true
        expect(subject.reorder?).to be true
      end
    end

    context 'when assignment_policies feature is disabled' do
      subject { described_class.new(owner_user, assignment_policy) }

      before do
        allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(false)
      end

      it 'denies actions with failure reason' do
        expect(subject.index?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
      end
    end

    context 'when user lacks permission' do
      subject { described_class.new(regular_user, assignment_policy) }

      before do
        allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(true)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
        expect(subject.update?).to be false
      end
    end
  end
end
