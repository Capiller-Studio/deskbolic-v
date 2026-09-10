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
end
