# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::NotificationSettingPolicy do
  subject { described_class.new(user, setting) }

  let(:user) { create(:user) }
  let(:setting) { create(:notification_setting, user: user) }


  describe 'permissions' do
    it 'permits edit and update for user setting' do
      expect(subject.edit?).to be true
      expect(subject.update?).to be true
    end

    it 'denies edit and update for another user setting' do
      other_user = create(:user)
      other_setting = create(:notification_setting, user: other_user)
      policy = described_class.new(user, other_setting)
      expect(policy.edit?).to be false
      expect(policy.update?).to be false
    end
  end
end
