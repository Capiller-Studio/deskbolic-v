# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::NotificationPolicy do
  subject { described_class.new(user, notification) }

  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:notification) { create(:notification, user: user) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end


  describe 'permissions' do
    it 'permits index, update_badge, mark_all_read, mark_read' do
      expect(subject.index?).to be true
      expect(subject.update_badge?).to be true
      expect(subject.mark_all_read?).to be true
      expect(subject.mark_read?).to be true
    end

    it 'denies mark_read if notification belongs to another user' do
      other_user = create(:user)
      other_notification = create(:notification, user: other_user)
      policy = described_class.new(user, other_notification)
      expect(policy.mark_read?).to be false
    end
  end

  describe 'Scope' do
    it 'resolves notifications for current user' do
      notification1 = create(:notification, user: user)
      other_user = create(:user)
      notification2 = create(:notification, user: other_user)

      scope = Dashboard::NotificationPolicy::Scope.new(user, Notification).resolve
      expect(scope).to include(notification1)
      expect(scope).not_to include(notification2)
    end
  end
end
