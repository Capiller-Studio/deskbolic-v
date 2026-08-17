# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ConversationPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner' do
      subject { described_class.new(owner_user, conversation) }

      it 'permits index, show, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when user has custom permissions' do
      subject { described_class.new(custom_user, conversation) }

      let(:custom_user) { create(:user) }
      let!(:custom_account_user) { create(:account_user, account: account, user: custom_user) }
      let(:role) { create(:access_role, account: account, permissions: { 'conversations' => { 'read' => true } }) }
      let!(:account_user_role) { create(:access_account_user_role, account: account, account_user: custom_account_user, role: role) }


      it 'permits read but denies write and delete' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be false
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end

    context 'when monthly conversation limit is reached' do
      subject { described_class.new(owner_user, conversation) }

      before do
        allow(account).to receive(:limit_reached?).with(:conversations_monthly, strict: false).and_return(true)
      end

      it 'denies create action and sets failure reason' do
        expect(subject.create?).to be false
        expect(subject.authorization_failure_reason).to eq(:limit_reached)
        expect(subject.authorization_failure_limit).to eq(:conversations_monthly)
      end
    end

    context 'when user has no account_user' do
      subject { described_class.new(stranger, conversation) }

      let(:stranger) { create(:user) }


      it 'denies all actions' do
        expect(subject.index?).to be false
        expect(subject.show?).to be false
        expect(subject.create?).to be false
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
