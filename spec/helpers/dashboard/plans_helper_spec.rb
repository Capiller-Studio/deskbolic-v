# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PlansHelper, type: :helper do
  let(:plan) { create(:plan, limits: { 'customers' => 1000, 'conversations_monthly' => 500, 'messages_monthly' => -1, 'data_retention_months' => 12 }, features: { 'sla' => true, 'api_access' => true, 'sso' => true, 'scim' => true }) }

  describe '#plan_features' do
    context 'when plan is a known marketing plan' do
      it 'returns marketing card feature highlights for symbolic' do
        symbolic_plan = build(:plan, name: Plan::SYMBOLIC)
        features = helper.plan_features(symbolic_plan)
        expect(features).to include('1–2 users, 1 channel')
        expect(features).to include('500 customers')
        expect(features).to include('Web widget channel')
      end

      it 'returns marketing highlights with everything_in for anabolic' do
        anabolic_plan = build(:plan, name: Plan::ANABOLIC)
        features = helper.plan_features(anabolic_plan)
        expect(features.first).to eq('Everything in Symbolic, plus:')
        expect(features).to include('100 free AI credits/mo')
        expect(features).to include('AI Copilot (Rely AI)')
      end

      it 'returns marketing highlights with everything_in for hyperbolic' do
        hyperbolic_plan = build(:plan, name: Plan::HYPERBOLIC)
        features = helper.plan_features(hyperbolic_plan)
        expect(features.first).to eq('Everything in Anabolic, plus:')
        expect(features).to include('250 free AI credits/mo')
        expect(features).to include('AI Agents (up to 3)')
      end
    end

    context 'when plan is a custom plan without preset card features' do
      let(:custom_plan) { build(:plan, name: 'custom_enterprise', limits: { 'customers' => 1000, 'conversations_monthly' => 500, 'messages_monthly' => -1, 'data_retention_months' => 12 }, features: { 'sla' => true, 'api_access' => true, 'sso' => true, 'scim' => true }) }

      it 'returns list of limit strings and enabled features as fallback' do
        features = helper.plan_features(custom_plan)
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
