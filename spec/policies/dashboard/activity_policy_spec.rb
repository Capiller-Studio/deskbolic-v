# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ActivityPolicy do
  subject { described_class.new(user, activity) }

  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:activity) { create(:activity, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe '#append_activity?' do
    it 'returns true if activity belongs to current account' do
      expect(subject.append_activity?).to be true
    end

    it 'returns false if activity belongs to another account' do
      other_account = create(:account)
      other_activity = create(:activity, account: other_account)
      policy = described_class.new(user, other_activity)
      expect(policy.append_activity?).to be false
    end
  end
end
