# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Conversations', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /conversations' do
    it 'renders conversations index' do
      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /conversations/:id' do
    it 'renders conversation show' do
      get conversation_path(id: conversation.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /conversations/:id' do
    it 'updates conversation status' do
      patch conversation_path(id: conversation.id, locale: :en), params: { conversation: { status: 'resolved' } }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.reload.status).to eq('resolved')
    end

    it 'updates conversation priority' do
      patch conversation_path(id: conversation.id, locale: :en), params: { conversation: { priority: 'urgent' } }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.reload.priority).to eq('urgent')
    end
  end

  describe 'Agent inbox scoping and access control' do
    let(:agent) { create(:user, confirmed_at: Time.current) }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent) }
    let(:other_inbox) { create(:inbox, account: account, name: 'Secret Inbox') }
    let(:other_conv) { create(:conversation, account: account, inbox: other_inbox) }
    let!(:other_member) { create(:conversation_member, conversation: other_conv, member: customer, account: account) }

    before do
      sign_in agent
    end

    it 'scopes navigation inboxes to assigned ones for agents' do
      account.with_shard do
        inbox.assign_users([ agent.id ])
      end

      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(inbox.name)
      expect(response.body).not_to include(other_inbox.name)
    end

    it 'prevents agents from viewing conversations in an unassigned inbox' do
      get conversations_path(resource_id: other_inbox.id, locale: :en)
      expect(response).to redirect_to(root_path)
    end

    it 'allows agents to view conversations in an assigned inbox' do
      account.with_shard do
        inbox.assign_users([ agent.id ])
      end

      get conversations_path(resource_id: inbox.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Owner conversation visibility and sidebar counts' do
    let(:agent) { create(:user, confirmed_at: Time.current) }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent) }
    let!(:assigned_to_agent_conv) do
      create(:conversation, account: account, inbox: inbox, assignee: agent, status: :active)
    end
    let!(:assigned_member) do
      create(:conversation_member, conversation: assigned_to_agent_conv, member: customer, account: account)
    end

    it 'allows account owner to view conversations assigned to other agents' do
      get conversations_path(resource_id: inbox.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("conversation_#{assigned_to_agent_conv.id}")
    end

    it 'accurately reflects active conversation counts in sidebar' do
      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<span class="sidebar-link-count">2</span>')
    end

    it 'does not crash and ignores invalid or removed assignee_id in query params' do
      removed_user = create(:user)
      get conversations_path(assignee_id: removed_user.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end

    it 'excludes removed account users from the TEAMMATES sidebar list' do
      team = account.with_shard { create(:team, account: account, name: 'Support Squad') }
      removed_user = create(:user, first_name: 'John', last_name: 'Doe')
      account_user = create(:account_user, account: account, user: removed_user)
      account.with_shard { create(:team_user, team: team, user: removed_user) }
      account_user.destroy

      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('John Doe')
    end

    it 'renders matching turbo-frame for lazy-loaded conversation pages' do
      22.times do
        create(:conversation, account: account, inbox: inbox)
      end

      get conversations_path(page: 2, locale: :en), headers: { 'Turbo-Frame' => 'conversations-page-2' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="conversations-page-2"')
      expect(response.body).not_to include('Content missing')
    end
  end
end
