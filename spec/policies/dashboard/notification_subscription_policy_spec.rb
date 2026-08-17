# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::NotificationSubscriptionPolicy do
  subject { described_class.new(user, subscription) }

  let(:user) { create(:user) }
  let(:subscription) { create(:notification_subscription, user: user) }


  describe 'permissions' do
    it 'permits create and destroy for user subscription' do
      expect(subject.create?).to be true
      expect(subject.destroy?).to be true
    end

    it 'denies actions for another user subscription' do
      other_user = create(:user)
      other_sub = create(:notification_subscription, user: other_user)
      policy = described_class.new(user, other_sub)
      expect(policy.create?).to be false
      expect(policy.destroy?).to be false
    end
  end
end
