# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::IntegrationPolicy do
  subject { described_class.new(owner_user, integration_record) }

  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:integration_record) { double('Integration') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits index, create, update, destroy, slack_callback' do
      expect(subject.index?).to be true
      expect(subject.create?).to be true
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.slack_callback?).to be true
    end
  end
end
