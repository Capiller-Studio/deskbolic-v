# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CustomerPolicy do
  subject { described_class.new(owner_user, customer) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:customer) { create(:customer, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits index, show, create, update, destroy for authorized user' do
      expect(subject.index?).to be true
      expect(subject.show?).to be true
      expect(subject.create?).to be true
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
    end
  end
end
