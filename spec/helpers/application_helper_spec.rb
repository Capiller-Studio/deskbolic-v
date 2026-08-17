# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#can?' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:conversation) { create(:conversation, account: account) }

    before do
      Current.account = account
    end

    after do
      Current.account = nil
    end

    it 'delegates action check to policy' do
      policy_double = double('ConversationPolicy', show?: true)
      allow(helper).to receive(:policy).with(conversation).and_return(policy_double)

      expect(helper.can?(:show, conversation)).to be true
    end
  end

  describe '#plan_upgrade_bubble' do
    let(:account) { create(:account) }

    before do
      Current.account = account
    end

    after do
      Current.account = nil
    end

    it 'returns nil when feature is enabled' do
      allow(account).to receive(:feature_enabled?).with('custom_branding').and_return(true)
      expect(helper.plan_upgrade_bubble('custom_branding')).to be_nil
    end

    it 'returns upgrade bubble HTML when feature is disabled' do
      allow(account).to receive(:feature_enabled?).with('custom_branding').and_return(false)
      result = helper.plan_upgrade_bubble('custom_branding')
      expect(result).to include('Upgrade')
      expect(result).to include('🔒')
    end
  end
end
