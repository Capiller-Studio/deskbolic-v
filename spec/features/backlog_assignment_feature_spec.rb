# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Backlog Assignment Feature', type: :feature do
  let(:account) { create(:account, status: :active) }
  let(:user) { create(:user, first_name: 'Alice', last_name: 'Agent', confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account, name: 'Website Support Form', auto_assign: true) }
  let!(:inbox_user) { create(:inbox_user, inbox: inbox, user: user) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  context 'when an unassigned conversation exists in the backlog' do
    let!(:conversation) do
      create(:conversation, account: account, inbox: inbox, status: :active, assignee_id: nil)
    end

    it 'shows conversation in unassigned state and auto-assigns when QueueDrainer runs' do
      visit conversation_path(id: conversation.id, locale: :en)

      expect(page).to have_text("##{conversation.identifier}")
      expect(page).to have_text('UnassignedAgent')

      # Simulate agent online in Redis
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return([ user.id.to_s ])

      # Execute queue draining
      AssignmentPolicies::QueueDrainer.call(account_id: account.id, inbox_id: inbox.id)

      # Reload page and verify assigned to Alice Agent
      visit conversation_path(id: conversation.id, locale: :en)
      expect(conversation.reload.assignee_id).to eq(user.id)
      expect(page).to have_text('Alice Agent')
    end
  end
end
