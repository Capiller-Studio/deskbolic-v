# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::TeamPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:team) { create(:team, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when teams feature is enabled' do
      subject { described_class.new(owner_user, team) }

      before do
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(true)
      end

      it 'permits index, show, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.show?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when teams feature is disabled' do
      subject { described_class.new(owner_user, team) }

      before do
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(false)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end
end
