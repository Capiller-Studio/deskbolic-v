# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ApiKeyPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:api_key) { double('ApiKey') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and feature api_access is enabled' do
      subject { described_class.new(owner_user, api_key) }

      before do
        allow(account).to receive(:feature_enabled?).with('api_access').and_return(true)
      end

      it 'permits index, create, and destroy' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when api_access feature is disabled' do
      subject { described_class.new(owner_user, api_key) }

      before do
        allow(account).to receive(:feature_enabled?).with('api_access').and_return(false)
      end

      it 'denies all actions with feature_not_enabled' do
        expect(subject.index?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
      end
    end

    context 'when user lacks account.manage permission' do
      subject { described_class.new(regular_user, api_key) }

      before do
        allow(account).to receive(:feature_enabled?).with('api_access').and_return(true)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
