# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SettingPolicy do
  subject { described_class.new(owner_user, setting_record) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:setting_record) { double('Setting') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits show and update' do
      expect(subject.show?).to be true
      expect(subject.update?).to be true
    end
  end
end
