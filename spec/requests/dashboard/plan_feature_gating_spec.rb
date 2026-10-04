# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::PlanFeatureGating', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:basic_plan) do
    create(:plan,
      name: 'Starter Plan',
      features: { 'roles' => true },
      limits: { 'channels' => 2, 'users' => 2 }
    )
  end

  let(:pro_plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'roles' => true,
        'channels' => { 'custom' => true },
        'identity_sources' => true,
        'sla' => true,
        'business_hours' => true,
        'automations' => true,
        'custom_fields' => true,
        'audit_logs' => true,
        'sso' => true
      },
      limits: {
        'channels' => 50,
        'users' => 50,
        'identity_sources' => 50,
        'sla_policies' => 50,
        'business_hour_groups' => 50,
        'automations' => 50,
        'custom_fields' => 50
      }
    )
  end

  let!(:subscription) { create(:subscription, account: account, plan: basic_plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'when features are not included in current plan' do
    it 'blocks Custom Channels and redirects to billing with upgrade notice' do
      get channels_custom_index_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Custom Channels' is not available on your current plan. Please upgrade to access it.")

      post channels_custom_index_path, params: {
        channel_custom: { name: 'Blocked Custom Channel', webhook_url: 'https://example.com/hook' }
      }
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Custom Channels' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks Identity Sources and redirects to billing with upgrade notice' do
      get identity_sources_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Identity Sources' is not available on your current plan. Please upgrade to access it.")

      post identity_sources_path, params: {
        identity_source: { name: 'Blocked Source', source_url: 'https://example.com/api', source_type: 'api' }
      }
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Identity Sources' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks SLA Policies and redirects to billing with upgrade notice' do
      get sla_policies_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'SLA Policies' is not available on your current plan. Please upgrade to access it.")

      post sla_policies_path, params: {
        sla_policy: {
          name: 'Blocked SLA',
          initial_response_value: '30',
          initial_response_unit: 'minutes',
          resolution_value: '4',
          resolution_unit: 'hours'
        }
      }
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'SLA Policies' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks Business Hours and redirects to billing with upgrade notice' do
      get business_hour_groups_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Business Hours' is not available on your current plan. Please upgrade to access it.")

      post business_hour_groups_path, params: {
        business_hour_group: { name: 'Blocked Business Hours', timezone: 'UTC' }
      }
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Business Hours' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks Automations and redirects to billing' do
      get automations_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Automations' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks Custom Fields and redirects to billing' do
      get custom_fields_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Custom Fields' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks Audit Logs and redirects to billing' do
      get settings_audit_logs_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'Audit Logs' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks CSAT Surveys and redirects to billing' do
      get csat_surveys_path
      expect(response).to redirect_to(dashboard_billing_path)
      expect(flash[:alert]).to eq("The feature 'CSAT Surveys' is not available on your current plan. Please upgrade to access it.")
    end

    it 'blocks SSO Settings and redirects with upgrade notice' do
      get settings_sso_path
      expect(response).to redirect_to(settings_general_path)
      expect(flash[:alert]).to include('Enterprise SSO is available on the Parabolic plan')
    end
  end

  describe 'when account is upgraded to a plan supporting the features' do
    before do
      subscription.update!(plan: pro_plan)
    end

    it 'allows access and creation of Custom Channels' do
      get channels_custom_index_path
      expect(response).to have_http_status(:ok)

      expect {
        post channels_custom_index_path, params: {
          channel_custom: { name: 'Pro Channel Bot', webhook_url: 'https://example.com/webhook' }
        }
      }.to change { account.with_shard { Channel::Custom.where(account_id: account.id).count } }.by(1)

      expect(response).to be_redirect
    end

    it 'allows access and creation of Identity Sources' do
      get identity_sources_path
      expect(response).to have_http_status(:ok)

      expect {
        post identity_sources_path, params: {
          identity_source: { name: 'Pro CRM Identity', source_url: 'https://example.com/api', source_type: 'api' }
        }
      }.to change { account.with_shard { IdentitySource.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(identity_sources_path)
    end

    it 'allows access and creation of SLA Policies' do
      get sla_policies_path
      expect(response).to have_http_status(:ok)

      expect {
        post sla_policies_path, params: {
          sla_policy: {
            name: 'Enterprise VIP SLA',
            description: 'Top tier response guarantee',
            initial_response_value: '15',
            initial_response_unit: 'minutes',
            resolution_value: '2',
            resolution_unit: 'hours'
          }
        }
      }.to change { account.with_shard { SlaPolicy.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(sla_policies_path)
    end

    it 'allows access and creation of Business Hours' do
      get business_hour_groups_path
      expect(response).to have_http_status(:ok)

      expect {
        post business_hour_groups_path, params: {
          business_hour_group: { name: 'Global Support Shifts', timezone: 'UTC' }
        }
      }.to change { account.with_shard { BusinessHourGroup.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(business_hour_groups_path)
    end

    it 'allows access to Automations, Custom Fields, Audit Logs, and SSO' do
      get automations_path
      expect(response).to have_http_status(:ok)

      get custom_fields_path
      expect(response).to have_http_status(:ok)

      get settings_audit_logs_path
      expect(response).to have_http_status(:ok)

      get settings_sso_path
      expect(response).to have_http_status(:ok)
    end
  end
end
