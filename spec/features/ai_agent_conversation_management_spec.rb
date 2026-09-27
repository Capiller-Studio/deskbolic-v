# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AI Agent Conversation Management Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal, name: 'Deskbolic Bot') }
  let(:inbox) { create(:inbox, account: account, ai_agent: ai_agent, name: 'Support Inbox') }
  let(:customer) { create(:customer, account: account, email: 'ahsan@example.com', name: 'Ahsan Khan') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active, ai_status: :ai_active) }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'Viewing and managing an AI-assisted conversation' do
    it 'displays AI agent messages and knowledge citations in conversation history' do
      create(:message, conversation: conversation, sender: customer, account: account, content: 'How do I reset my password?')
      create(
        :message,
        conversation: conversation,
        sender: ai_agent,
        account: account,
        content: '<p>Hello Ahsan! Visit the login page to reset your password. <a href="https://helpbolic.com/en/articles/reset">Read Article</a></p>'
      )

      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_text('Ahsan Khan')
      expect(page).to have_text('How do I reset my password?')
      expect(page).to have_text('Hello Ahsan! Visit the login page to reset your password.')
      expect(page).to have_link('Read Article', href: 'https://helpbolic.com/en/articles/reset')
    end

    it 'interrupts AI agent, clears debounce buffer, and sets status to handed off when human agent replies publicly' do
      expect(Ai::MessageDebouncer).to receive(:clear!).with(account.id, conversation.id)

      create(
        :message,
        conversation: conversation,
        sender: user,
        account: account,
        content: 'Hi Ahsan, I am stepping in to assist you directly.',
        visibility: :global
      )

      expect(conversation.reload.ai_status).to eq('ai_handed_off')

      visit conversation_path(id: conversation.id, locale: :en)
      expect(page).to have_text('Hi Ahsan, I am stepping in to assist you directly.')
    end

    it 'does not interrupt AI agent when human agent adds a private personal note' do
      expect(Ai::MessageDebouncer).not_to receive(:clear!)

      create(
        :message,
        conversation: conversation,
        sender: user,
        account: account,
        content: 'Customer is exploring upgrade options to Enterprise.',
        visibility: :personal
      )

      expect(conversation.reload.ai_status).to eq('ai_active')
    end
  end
end
