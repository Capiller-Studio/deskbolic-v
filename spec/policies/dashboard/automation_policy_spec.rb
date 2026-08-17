# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AutomationPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:automation) { create(:automation, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and feature is enabled' do
      subject { described_class.new(owner_user, automation) }

      before do
        allow(account).to receive(:feature_enabled?).with(:automations).and_return(true)
      end

      it 'permits index, show, create, update, destroy, toggle, duplicate, reorder, lookups' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
        expect(subject.toggle?).to be true
        expect(subject.duplicate?).to be true
        expect(subject.reorder?).to be true
        expect(subject.lookups?).to be true
      end
    end

    context 'when system automation' do
      let(:system_automation) { create(:automation, account: account, is_system: true) }

      it 'allows owner to update but not destroy' do
        policy = described_class.new(owner_user, system_automation)
        allow(account).to receive(:feature_enabled?).with(:automations).and_return(true)
        expect(policy.update?).to be true
        expect(policy.destroy?).to be false
      end

      it 'denies non-owner to update or destroy' do
        role = create(:access_role, account: account, permissions: { 'automations' => { 'manage' => true } })
        create(:access_account_user_role, account: account, account_user: regular_account_user, role: role)
        policy = described_class.new(regular_user, system_automation)
        allow(account).to receive(:feature_enabled?).with(:automations).and_return(true)
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end

    context 'when limit is reached' do
      subject { described_class.new(owner_user, automation) }

      before do
        allow(account).to receive(:feature_enabled?).with(:automations).and_return(true)
        allow(account).to receive(:limit_reached?).with(:automations, strict: true).and_return(true)
      end

      it 'denies create with limit_reached failure reason' do
        expect(subject.create?).to be false
        expect(subject.authorization_failure_reason).to eq(:limit_reached)
      end
    end
  end
end
