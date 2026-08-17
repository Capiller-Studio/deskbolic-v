# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::HelpCenter::CategoryPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:category) { create(:help_center_category, portal: portal) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when help_center_portals feature is enabled' do
      subject { described_class.new(owner_user, category) }

      before do
        allow(account).to receive(:feature_enabled?).with(:help_center_portals).and_return(true)
      end

      it 'permits index, create, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.create?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when help_center_portals feature is disabled' do
      subject { described_class.new(owner_user, category) }

      before do
        allow(account).to receive(:feature_enabled?).with(:help_center_portals).and_return(false)
      end

      it 'denies index and create' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end
end
