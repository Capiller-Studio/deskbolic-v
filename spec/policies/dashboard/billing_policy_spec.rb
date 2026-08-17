# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::BillingPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:billing) { double('Billing') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner' do
      subject { described_class.new(owner_user, billing) }

      it 'permits show and update' do
        expect(subject.show?).to be true
        expect(subject.update?).to be true
      end
    end

    context 'when user has billing.manage permission' do
      subject { described_class.new(regular_user, billing) }

      let(:role) { create(:access_role, account: account, permissions: { 'billing' => { 'manage' => true } }) }
      let!(:account_user_role) { create(:access_account_user_role, account: account, account_user: regular_account_user, role: role) }


      it 'permits show and update' do
        expect(subject.show?).to be true
        expect(subject.update?).to be true
      end
    end

    context 'when user lacks permission' do
      subject { described_class.new(regular_user, billing) }

      it 'denies show and update' do
        expect(subject.show?).to be false
        expect(subject.update?).to be false
      end
    end
  end
end
