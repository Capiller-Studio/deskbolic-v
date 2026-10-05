# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Macros', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active) }
  let(:macro) do
    create(:macro,
      account: account,
      name: 'Close & Resolve',
      visibility: :account_wide,
      status: :active,
      actions: [
        { 'action' => 'set_status', 'params' => { 'status' => 'resolved' } }
      ]
    )
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
    account.with_shard { Macro.delete_all }
  end

  describe 'GET /macros' do
    it 'renders macros index' do
      get macros_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end

    it 'filters macros by visibility' do
      personal = create(:macro, :personal, account: account, scopeable: user, name: 'Personal Macro')
      shared = create(:macro, account: account, visibility: :account_wide, name: 'Shared Macro')

      get macros_path(locale: :en, visibility: 'personal')
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Personal Macro')
      expect(response.body).not_to include('Shared Macro')
    end

    it 'filters macros by query' do
      match = create(:macro, account: account, name: 'Billing Refund Macro')
      other = create(:macro, account: account, name: 'Tech Support')

      get macros_path(locale: :en, q: 'Refund')
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Billing Refund Macro')
      expect(response.body).not_to include('Tech Support')
    end
  end

  describe 'GET /macros/new' do
    it 'renders new macro form' do
      get new_macro_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /macros/:id/edit' do
    it 'renders edit macro form' do
      get edit_macro_path(id: macro.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /macros' do
    it 'creates a new macro with array actions' do
      post macros_path(locale: :en), params: {
        macro: {
          name: 'Escalate to Tier 2',
          visibility: 'account_wide',
          actions: [ { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } } ]
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Macro.where(name: 'Escalate to Tier 2') }).to exist
    end

    it 'creates a macro when actions are sent as JSON string' do
      actions_json = [
        { 'action' => 'add_label', 'params' => { 'label_ids' => [ 'support' ] } }
      ].to_json

      post macros_path(locale: :en), params: {
        macro: {
          name: 'Tag Support',
          visibility: 'account_wide',
          actions: actions_json
        }
      }
      expect(response).to have_http_status(:redirect)
      created = account.with_shard { Macro.find_by(name: 'Tag Support') }
      expect(created).to be_present
      expect(created.actions.first['action']).to eq('add_label')
    end

    it 'creates a personal macro scoped to current_user' do
      post macros_path(locale: :en), params: {
        macro: {
          name: 'My Special Macro',
          visibility: 'personal',
          actions: [ { 'action' => 'set_priority', 'params' => { 'priority' => 'low' } } ]
        }
      }
      expect(response).to have_http_status(:redirect)
      created = account.with_shard { Macro.find_by(name: 'My Special Macro') }
      expect(created.visibility).to eq('personal')
      expect(created.scopeable).to eq(user)
    end

    it 'creates a team macro scoped to the team' do
      team = create(:team, account: account)
      create(:team_user, team: team, user: user)

      post macros_path(locale: :en), params: {
        macro: {
          name: 'Team Onboarding',
          visibility: 'team',
          team_id: team.id,
          actions: [ { 'action' => 'set_priority', 'params' => { 'priority' => 'medium' } } ]
        }
      }
      expect(response).to have_http_status(:redirect)
      created = account.with_shard { Macro.find_by(name: 'Team Onboarding') }
      expect(created.visibility).to eq('team')
      expect(created.scopeable).to eq(team)
    end

    it 'returns unprocessable_entity on invalid params' do
      post macros_path(locale: :en), params: {
        macro: {
          name: '',
          actions: []
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /macros/:id' do
    it 'updates macro attributes without wiping existing actions' do
      patch macro_path(id: macro.id, locale: :en), params: {
        macro: { name: 'Close & Archive' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { macro.reload.name }).to eq('Close & Archive')
      expect(account.with_shard { macro.actions }).not_to be_empty
    end

    it 'updates scopeable when visibility changes from personal to account_wide' do
      personal = create(:macro, :personal, account: account, scopeable: user)
      patch macro_path(id: personal.id, locale: :en), params: {
        macro: { visibility: 'account_wide' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { personal.reload.visibility }).to eq('account_wide')
      expect(account.with_shard { personal.scopeable }).to be_nil
    end
  end

  describe 'DELETE /macros/:id' do
    it 'destroys macro with HTML redirect' do
      delete macro_path(id: macro.id, locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { Macro.where(id: macro.id) }).not_to exist
    end

    it 'destroys macro with Turbo Stream' do
      delete macro_path(id: macro.id, locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(action="remove" target="macro_#{macro.id}"))
    end
  end

  describe 'PATCH /macros/:id/toggle' do
    it 'toggles status from active to inactive' do
      expect(macro.active?).to be true
      patch toggle_macro_path(id: macro.id, locale: :en), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(account.with_shard { macro.reload.inactive? }).to be true
      expect(response.body).to include(%(action="replace" target="macro_#{macro.id}"))
    end
  end

  describe 'GET /macros/available' do
    it 'returns JSON list of available executable macros' do
      macro # ensure created
      inactive_macro = create(:macro, account: account, status: :inactive, name: 'Hidden Inactive')

      get available_macros_path(locale: :en), as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      ids = json['macros'].pluck('id')
      expect(ids).to include(macro.id)
      expect(ids).not_to include(inactive_macro.id)
    end

    it 'returns HTML partial for conversation picker' do
      macro
      get available_macros_path(locale: :en, conversation_id: conversation.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(macro.name))
    end

    it 'filters available macros by query' do
      get available_macros_path(locale: :en, q: 'NonExistentMacroName'), as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['macros']).to be_empty
    end
  end

  describe 'POST /macros/:id/execute' do
    it 'executes the macro on conversation via Turbo Stream' do
      expect(conversation.status).to eq('active')

      post execute_macro_path(id: macro.id, conversation_id: conversation.id, locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])

      expect(account.with_shard { conversation.reload.status }).to eq('resolved')
      expect(response.body).to include('flash-messages')
      expect(response.body).to include("conversation-details-#{conversation.id}")
      expect(response.body).to include("conversation_#{conversation.id}")
    end

    it 'executes the macro on conversation via JSON' do
      post execute_macro_path(id: macro.id, conversation_id: conversation.id, locale: :en), as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['success']).to be true
      expect(json['status']).to eq('success')
    end

    it 'refuses to execute an inactive macro' do
      macro.update_column(:status, Macro.statuses[:inactive])

      post execute_macro_path(id: macro.id, conversation_id: conversation.id, locale: :en), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
