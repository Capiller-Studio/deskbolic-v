# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::MacroPolicy do
  subject { described_class.new(owner_user, macro) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:macro_role) { create(:access_role, account: account, permissions: { 'macros' => [ 'execute', 'read' ] }) }
  let!(:user_role) { create(:access_account_user_role, account: account, account_user: regular_account_user, role: macro_role) }

  let(:macro) { create(:macro, :personal, account: account, scopeable: owner_user, status: :active) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions for owner' do
    it 'permits index, show, create, update, destroy, toggle, available, execute' do
      expect(subject.index?).to be true
      expect(subject.show?).to be true
      expect(subject.create?).to be true
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.toggle?).to be true
      expect(subject.available?).to be true
      expect(subject.execute?).to be true
    end

    context 'when system macro' do
      let(:system_macro) { create(:macro, account: account, system_provided: true, status: :active) }

      it 'allows owner to update but not destroy' do
        policy = described_class.new(owner_user, system_macro)
        expect(policy.update?).to be true
        expect(policy.destroy?).to be false
      end
    end
  end

  describe '#execute?' do
    it 'allows execution when macro is active and visible to user' do
      expect(subject.execute?).to be true
    end

    it 'denies execution when macro is inactive' do
      macro.update_column(:status, Macro.statuses[:inactive])
      expect(subject.execute?).to be false
    end

    it 'denies execution when user cannot view the personal macro' do
      policy = described_class.new(regular_user, macro)
      expect(policy.execute?).to be false
    end

    context 'team scoped macro' do
      let(:team) { create(:team, account: account) }
      let(:team_macro) { create(:macro, :team, account: account, scopeable: team, status: :active) }

      it 'allows execution if user is a member of the team' do
        create(:team_user, team: team, user: regular_user)
        policy = described_class.new(regular_user, team_macro)
        expect(policy.execute?).to be true
      end

      it 'denies execution if user is not a member of the team' do
        policy = described_class.new(regular_user, team_macro)
        expect(policy.execute?).to be false
      end
    end
  end

  describe '#toggle?' do
    it 'allows toggle for owner' do
      expect(subject.toggle?).to be true
    end

    it 'denies toggle for non-owner on someone else personal macro' do
      policy = described_class.new(regular_user, macro)
      expect(policy.toggle?).to be false
    end
  end

  describe '#available?' do
    it 'allows checking available macros for any agent with read/execute permission' do
      policy = described_class.new(regular_user, Macro)
      # regular_user by default has base agent permissions in tests or owner can execute
      expect(policy.available?).to be true
    end
  end
end
