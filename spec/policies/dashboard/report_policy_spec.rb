# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ReportPolicy do
  subject { described_class.new(owner_user, report_record) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:report_record) { double('Report') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits index, show, export' do
      expect(subject.index?).to be true
      expect(subject.show?).to be true
      expect(subject.export?).to be true
    end
  end
end
