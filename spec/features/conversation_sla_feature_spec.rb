# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Conversation SLA Details Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account, name: 'Support Inbox') }
  let(:sla_policy) { create(:sla_policy, account: account, name: 'VIP Tracker') }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  context 'when conversation SLA has breached' do
    let!(:conversation) do
      create(:conversation, account: account, inbox: inbox, status: :active, title: 'Urgent Issue')
    end
    let!(:conversation_sla) do
      create(:conversation_sla,
        account: account,
        conversation: conversation,
        sla_policy: sla_policy,
        status: :failed,
        target_first_response_at: 1.hour.ago,
        target_resolution_at: 30.minutes.ago
      )
    end

    it 'displays breached status badge and policy targets in conversation details drawer' do
      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_text("##{conversation.identifier}")
      expect(page).to have_text('SLA Status')
      expect(page).to have_text('Breached')
      expect(page).to have_text('VIP Tracker')
      expect(page).to have_text('First Response Target')
      expect(page).to have_text('Resolution Target')
    end
  end

  context 'when conversation SLA is on track' do
    let!(:conversation) do
      create(:conversation, account: account, inbox: inbox, status: :active)
    end
    let!(:conversation_sla) do
      create(:conversation_sla,
        account: account,
        conversation: conversation,
        sla_policy: sla_policy,
        status: :pending,
        target_first_response_at: 1.hour.from_now,
        target_resolution_at: 4.hours.from_now
      )
    end

    it 'displays on track status in conversation details drawer' do
      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_text("##{conversation.identifier}")
      expect(page).to have_text('SLA Status')
      expect(page).to have_text('On track')
      expect(page).to have_text('VIP Tracker')
    end
  end

  context 'when conversation SLA was achieved' do
    let!(:conversation) do
      create(:conversation,
        account: account,
        inbox: inbox,
        status: :resolved,
        first_respond_at: 1.hour.ago - 10.minutes,
        status_changed_at: 10.minutes.ago
      )
    end
    let!(:conversation_sla) do
      create(:conversation_sla,
        account: account,
        conversation: conversation,
        sla_policy: sla_policy,
        status: :successful,
        target_first_response_at: 1.hour.ago,
        target_resolution_at: 5.minutes.ago
      )
    end

    it 'displays achieved status in conversation details drawer' do
      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_text("##{conversation.identifier}")
      expect(page).to have_text('SLA Status')
      expect(page).to have_text('Achieved')
      expect(page).to have_text('VIP Tracker')
    end
  end
end
