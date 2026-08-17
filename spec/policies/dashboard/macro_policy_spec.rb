# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::MacroPolicy do
  subject { described_class.new(owner_user, macro) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:macro) { create(:macro, :personal, account: account, scopeable: owner_user) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits index, show, create, update, destroy, execute' do
      expect(subject.index?).to be true
      expect(subject.show?).to be true
      expect(subject.create?).to be true
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.execute?).to be true
    end

    context 'when system macro' do
      let(:system_macro) { create(:macro, account: account, is_system: true) }

      it 'allows owner to update but not destroy' do
        policy = described_class.new(owner_user, system_macro)
        expect(policy.update?).to be true
        expect(policy.destroy?).to be false
      end
    end
  end
end
