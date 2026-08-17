# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SkillPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:skill) { create(:skill, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when assignment_policies feature is enabled' do
      subject { described_class.new(owner_user, skill) }

      before do
        allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(true)
      end

      it 'permits index, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when assignment_policies feature is disabled' do
      subject { described_class.new(owner_user, skill) }

      before do
        allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(false)
      end

      it 'denies access' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end
end
