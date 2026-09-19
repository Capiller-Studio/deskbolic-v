# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ScimTokenPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:scim_token) { double('ScimToken') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and sso feature is enabled' do
      subject { described_class.new(owner_user, scim_token) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(true)
      end

      it 'permits index, create, and destroy' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when sso feature is disabled' do
      subject { described_class.new(owner_user, scim_token) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(false)
      end

      it 'denies actions with :feature_not_enabled' do
        expect(subject.index?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
        expect(subject.create?).to be false
        expect(subject.destroy?).to be false
      end
    end

    context 'when user lacks sso permissions' do
      subject { described_class.new(regular_user, scim_token) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(true)
      end

      it 'denies all actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
