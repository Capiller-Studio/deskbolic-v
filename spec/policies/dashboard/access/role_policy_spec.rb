# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Access::RolePolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:custom_role) { create(:access_role, account: account, system_provided: false) }
  let(:system_role) { create(:access_role, account: account, system_provided: true) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when custom_roles feature is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with(:roles).and_return(true)
        allow(account).to receive(:feature_enabled?).with(:custom_roles).and_return(true)
      end

      it 'permits full lifecycle on custom role' do
        policy = described_class.new(owner_user, custom_role)
        expect(policy.index?).to be true
        expect(policy.show?).to be true
        expect(policy.create?).to be true
        expect(policy.update?).to be true
        expect(policy.destroy?).to be true
      end

      it 'allows owner to update system role but not destroy' do
        policy = described_class.new(owner_user, system_role)
        expect(policy.update?).to be true
        expect(policy.destroy?).to be false
      end
    end
  end
end
