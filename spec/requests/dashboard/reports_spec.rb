# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Reports', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:plan) { create(:plan, currency: account.currency, status: :active) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /reports' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let!(:breached_conversation) { create(:conversation, account: account, inbox: inbox, created_at: 2.days.ago) }
    let!(:pending_conversation) { create(:conversation, account: account, inbox: inbox, created_at: 1.day.ago) }

    let!(:breached_sla) do
      create(:conversation_sla,
        account: account,
        conversation: breached_conversation,
        sla_policy: sla_policy,
        status: :failed
      )
    end

    let!(:pending_sla) do
      create(:conversation_sla,
        account: account,
        conversation: pending_conversation,
        sla_policy: sla_policy,
        status: :pending
      )
    end

    it 'accurately calculates total conversations and SLA breaches' do
      get reports_path(locale: :en)

      expect(response).to have_http_status(:ok)
      # @sla_breaches_count should be 1
      expect(response.body).to include('SLA Breaches')
      # Assigns check
      expect(controller.instance_variable_get(:@sla_breaches_count)).to eq(1)
      expect(controller.instance_variable_get(:@total_conversations_count)).to eq(2)
    end
  end
end
