# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Conversations Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account, name: 'Support Inbox') }
  let(:customer) { create(:customer, account: account, email: 'alex@example.com', name: 'Alex Johnson') }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  context 'when there are conversations' do
    let!(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active) }
    let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }
    let!(:message) { create(:message, conversation: conversation, sender: customer, account: account, content: 'Hello Deskbolic support team!') }

    it 'displays conversations in the list' do
      visit conversations_path

      expect(page).to have_content('Alex Johnson')
      expect(page).to have_content('Hello Deskbolic support team!')
    end

    it 'displays conversation details and messages when viewing a conversation' do
      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_content('Hello Deskbolic support team!')
      expect(page).to have_content('Alex Johnson')
    end
  end

  context 'when there are no conversations' do
    it 'displays the empty state message' do
      visit conversations_path

      expect(page).to have_content(I18n.t('dashboard.conversations.no_conversations_yet', default: 'No conversations yet'))
    end
  end

  context 'when conversations are assigned to other agents' do
    let(:agent) { create(:user, confirmed_at: Time.current, first_name: 'Sarah', last_name: 'Connor') }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent) }
    let!(:assigned_conversation) do
      create(:conversation, account: account, inbox: inbox, assignee: agent, status: :active)
    end
    let!(:assigned_member) do
      create(:conversation_member, conversation: assigned_conversation, member: customer, account: account)
    end
    let!(:assigned_message) do
      create(:message, conversation: assigned_conversation, sender: customer, account: account, content: 'Assigned to Sarah')
    end
    let!(:unassigned_conversation) do
      create(:conversation, account: account, inbox: inbox, status: :active)
    end
    let!(:unassigned_member) do
      create(:conversation_member, conversation: unassigned_conversation, member: customer, account: account)
    end

    it 'allows account owner to see conversations assigned to other agents' do
      visit conversations_path(resource_id: inbox.id)

      expect(page).to have_content('Alex Johnson')
      expect(page).to have_content('Assigned to Sarah')
    end

    it 'displays the active conversations count badge in sidebar' do
      visit conversations_path

      expect(page).to have_css('.sidebar-link-count', text: '2')
    end

    it 'scopes visibility for regular agents' do
      other_inbox = create(:inbox, account: account, name: 'Billing Inbox')
      secret_customer = create(:customer, account: account, email: 'secret@example.com', name: 'Secret Client')
      secret_conv = create(:conversation, account: account, inbox: other_inbox, status: :active)
      create(:conversation_member, conversation: secret_conv, member: secret_customer, account: account)
      create(:message, conversation: secret_conv, sender: secret_customer, account: account, content: 'Secret finance message')

      login_as(agent, scope: :user)

      account.with_shard do
        inbox.assign_users([ agent.id ])
      end

      visit conversations_path

      expect(page).to have_content('Support Inbox')
      expect(page).to have_content('Assigned to Sarah')

      expect(page).not_to have_content('Billing Inbox')
      expect(page).not_to have_content('Secret finance message')
    end
  end
end
