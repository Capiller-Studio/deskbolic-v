# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject { described_class.new(user, record) }

  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:record) { double('Record') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'default actions' do
    it 'denies all default actions' do
      expect(subject.index?).to be false
      expect(subject.show?).to be false
      expect(subject.create?).to be false
      expect(subject.new?).to be false
      expect(subject.update?).to be false
      expect(subject.edit?).to be false
      expect(subject.destroy?).to be false
    end
  end

  describe 'Scope' do
    it 'resolves all records in scope' do
      scope_relation = double('ScopeRelation', all: [ 'record1', 'record2' ])
      scope = ApplicationPolicy::Scope.new(user, scope_relation)
      expect(scope.resolve).to eq([ 'record1', 'record2' ])
    end
  end
end
