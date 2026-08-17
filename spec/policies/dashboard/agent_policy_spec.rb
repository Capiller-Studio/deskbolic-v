# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AgentPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:agent_user) { create(:user) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner' do
      subject { described_class.new(owner_user, agent_account_user) }

      it 'permits index, show, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when user has specific permissions' do
      subject { described_class.new(agent_user, agent_account_user) }

      let(:role) { create(:access_role, account: account, permissions: { 'agents' => { 'read' => true, 'invite' => true } }) }
      let!(:account_user_role) { create(:access_account_user_role, account: account, account_user: agent_account_user, role: role) }


      it 'permits index, show, create but denies update and destroy' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
