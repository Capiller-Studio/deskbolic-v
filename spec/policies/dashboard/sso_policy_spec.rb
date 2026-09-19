# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SsoPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:sso_record) { double('SsoConfiguration') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner and sso feature is enabled' do
      subject { described_class.new(owner_user, sso_record) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(true)
      end

      it 'permits show and update' do
        expect(subject.show?).to be true
        expect(subject.update?).to be true
      end
    end

    context 'when sso feature is disabled on workspace plan' do
      subject { described_class.new(owner_user, sso_record) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(false)
      end

      it 'denies actions with :feature_not_enabled failure reason' do
        expect(subject.show?).to be false
        expect(subject.authorization_failure_reason).to eq(:feature_not_enabled)
        expect(subject.update?).to be false
      end
    end

    context 'when user is regular agent lacking sso permissions' do
      subject { described_class.new(regular_user, sso_record) }

      before do
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(true)
      end

      it 'denies show and update' do
        expect(subject.show?).to be false
        expect(subject.update?).to be false
      end
    end

    context 'when user has a role with sso.read and sso.manage permissions' do
      subject { described_class.new(regular_user, sso_record) }

      let(:admin_role) do
        account.with_shard do
          create(:access_role, account: account, name: 'Custom Admin', permissions: {
            'sso' => { 'read' => true, 'manage' => true }
          })
        end
      end

      before do
        account.with_shard do
          create(:access_account_user_role, account_user: regular_account_user, role: admin_role)
        end
        allow(account).to receive(:feature_enabled?).with(:sso).and_return(true)
      end

      it 'permits show and update' do
        expect(subject.show?).to be true
        expect(subject.update?).to be true
      end
    end
  end
end
