# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports Dashboard Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account, name: 'Support') }
  let(:sla_policy) { create(:sla_policy, account: account, name: 'Standard Support') }

  let!(:breached_conversation) do
    create(:conversation, account: account, inbox: inbox, created_at: 2.days.ago, title: 'Breached ticket')
  end
  let!(:on_track_conversation) do
    create(:conversation, account: account, inbox: inbox, created_at: 1.day.ago, title: 'On track ticket')
  end

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
      conversation: on_track_conversation,
      sla_policy: sla_policy,
      status: :pending
    )
  end

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  it 'displays KPIs including total conversations and accurate SLA breaches count' do
    visit reports_path(locale: :en)

    expect(page).to have_text('Reports')
    expect(page).to have_text('Total Conversations')
    expect(page).to have_text('SLA Breaches')

    # Verify SLA breaches count is 1 (not 0)
    within('.ui-metric-card--red') do
      expect(page).to have_text(I18n.t('dashboard.reports.sla_breaches'))
      expect(page).to have_text('1')
    end

    # Verify total conversations is 2
    within('.ui-metric-card--purple') do
      expect(page).to have_text(I18n.t('dashboard.reports.total_conversations'))
      expect(page).to have_text('2')
    end
  end
end
