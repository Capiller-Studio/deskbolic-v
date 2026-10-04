# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Settings', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /settings' do
    it 'renders settings index' do
      get settings_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end

    context 'when on a free plan with gated features' do
      let(:plan) do
        create(:plan, :free, features: {
          'teams' => false,
          'help_center_portals' => false,
          'roles' => true,
          'csat' => false,
          'labels' => false,
          'macros' => false,
          'automations' => false,
          'ai_agent' => false,
          'email_templates' => false,
          'api_access' => false,
          'audit_logs' => false,
          'sso' => false,
          'channels' => {
            'email' => false,
            'web_widget' => true
          }
        })
      end

      it 'renders plan upgrade lock indicators for gated features in the sidebar' do
        get settings_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('plan-upgrade-lock')

        # Check that helper accurately reflects each gated and non-gated feature
        expect(account.feature_enabled?(:teams)).to be(false)
        expect(account.feature_enabled?(:help_center_portals)).to be(false)
        expect(account.feature_enabled?(:csat)).to be(false)
        expect(account.feature_enabled?(:labels)).to be(false)
        expect(account.feature_enabled?(:macros)).to be(false)
        expect(account.feature_enabled?(:automations)).to be(false)
        expect(account.feature_enabled?(:ai_agent)).to be(false)
        expect(account.feature_enabled?(:email_templates)).to be(false)
        expect(account.feature_enabled?(:roles)).to be(true)
        expect(account.feature_enabled?('channels.web_widget')).to be(true)
      end
    end

    context 'when on an enterprise plan with all features enabled' do
      let(:plan) do
        create(:plan, :paid, features: {
          'teams' => true,
          'help_center_portals' => true,
          'roles' => true,
          'sla' => true,
          'csat' => true,
          'labels' => true,
          'macros' => true,
          'automations' => true,
          'ai_agent' => true,
          'email_templates' => true,
          'api_access' => true,
          'audit_logs' => true,
          'sso' => true,
          'custom_fields' => true,
          'assignment_policies' => true,
          'business_hours' => true,
          'identity_sources' => true,
          'channels' => {
            'email' => true,
            'web_widget' => true,
            'custom' => true,
            'contact_form' => true,
            'facebook' => true,
            'instagram' => true,
            'whatsapp' => true
          }
        })
      end

      it 'does not render plan upgrade locks for any of the unlocked features' do
        get settings_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('plan-upgrade-lock')
      end
    end
  end
end
