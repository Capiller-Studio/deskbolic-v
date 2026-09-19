# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PlansHelper, type: :helper do
  let(:plan) { create(:plan, limits: { 'customers' => 1000, 'conversations_monthly' => 500, 'messages_monthly' => -1, 'data_retention_months' => 12 }, features: { 'sla' => true, 'api_access' => true, 'sso' => true, 'scim' => true }) }

  describe '#plan_features' do
    it 'returns list of limit strings and enabled features' do
      features = helper.plan_features(plan)
      expect(features).to include('1,000 customers')
      expect(features).to include('500 conversations/month')
      expect(features).to include('Unlimited messages/month')
      expect(features).to include('12 months data retention')
      expect(features).to include('SLA management')
      expect(features).to include('API access')
      expect(features).to include('Single sign-on (SSO)')
      expect(features).to include('SCIM directory sync')
    end
  end

  describe '#limit_feature, #retention_feature, #boolean_feature' do
    it 'formats limit features correctly' do
      expect(helper.limit_feature('Agents', 5)).to eq('5 agents')
      expect(helper.limit_feature('Agents', -1)).to eq('Unlimited agents')
      expect(helper.retention_feature(6)).to eq('6 months data retention')
      expect(helper.boolean_feature('Feature A', true)).to eq('Feature A')
      expect(helper.boolean_feature('Feature A', false)).to be_nil
    end
  end
end
