# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ChannelPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:regular_user) { create(:user) }
  let!(:regular_account_user) { create(:account_user, account: account, user: regular_user) }
  let(:channel) { double('Channel') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when user is owner' do
      subject { described_class.new(owner_user, channel) }

      it 'permits index' do
        expect(subject.index?).to be true
      end
    end

    context 'when user has inboxes.read permission' do
      subject { described_class.new(regular_user, channel) }

      let(:role) { create(:access_role, account: account, permissions: { 'inboxes' => { 'read' => true } }) }
      let!(:account_user_role) { create(:access_account_user_role, account: account, account_user: regular_account_user, role: role) }


      it 'permits index' do
        expect(subject.index?).to be true
      end
    end

    context 'when user lacks permission' do
      subject { described_class.new(regular_user, channel) }

      it 'denies index' do
        expect(subject.index?).to be false
      end
    end
  end
end
