# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Inboxes', type: :request do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:agent_user) { create(:user, confirmed_at: Time.current) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:team) { create(:team, account: account, name: 'Support Team') }
  let(:inbox) { create(:inbox, account: account, name: 'Support Inbox') }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe 'GET /inboxes' do
    it 'redirects to inboxes settings page' do
      get inboxes_path
      expect(response).to redirect_to(inboxes_settings_path)
    end
  end

  describe 'GET /inboxes/:id' do
    it 'renders the collaborators modal partial' do
      get inbox_path(id: inbox.id, modal: true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Collaborators')
      expect(response.body).to include(agent_user.email)
    end
  end

  describe 'PATCH /inboxes/:id/update_members' do
    it 'updates assigned users, teams, and auto_assign flag via HTML' do
      patch update_members_inbox_path(id: inbox.id), params: {
        user_ids: [agent_user.id],
        team_ids: [team.id],
        auto_assign: '1'
      }

      expect(response).to redirect_to(inboxes_settings_path)
      account.with_shard do
        inbox.reload
        expect(inbox.assigned_user_ids).to contain_exactly(agent_user.id.to_s)
        expect(inbox.assigned_team_ids).to contain_exactly(team.id.to_s)
        expect(inbox.auto_assign).to be true
      end
    end

    it 'updates assigned members via Turbo Stream' do
      patch update_members_inbox_path(id: inbox.id), params: {
        user_ids: [agent_user.id],
        team_ids: [],
        auto_assign: '0'
      }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include("inbox_card_#{inbox.id}")

      account.with_shard do
        inbox.reload
        expect(inbox.assigned_user_ids).to contain_exactly(agent_user.id.to_s)
        expect(inbox.assigned_team_ids).to be_empty
        expect(inbox.auto_assign).to be false
      end
    end
  end

  describe 'POST /inboxes/:id/add_member' do
    it 'adds a user to the inbox' do
      post add_member_inbox_path(id: inbox.id), params: {
        user_id: agent_user.id
      }

      expect(response).to redirect_to(inboxes_settings_path)
      account.with_shard do
        expect(inbox.inbox_users.where(user_id: agent_user.id)).to exist
      end
    end
  end

  describe 'DELETE /inboxes/:id/remove_member' do
    before do
      account.with_shard do
        inbox.inbox_users.create!(user_id: agent_user.id)
      end
    end

    it 'removes a user from the inbox' do
      delete remove_member_inbox_path(id: inbox.id), params: {
        user_id: agent_user.id
      }

      expect(response).to redirect_to(inboxes_settings_path)
      account.with_shard do
        expect(inbox.inbox_users.where(user_id: agent_user.id)).not_to exist
      end
    end
  end
end
