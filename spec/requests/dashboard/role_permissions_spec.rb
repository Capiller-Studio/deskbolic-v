# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::RolePermissions', type: :request do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  let(:agent_user) { create(:user, confirmed_at: Time.current) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

  # Plan with all features enabled so role gating is the controlling factor
  let(:pro_plan) do
    create(:plan,
      name: 'Parabolic Plan',
      features: {
        'roles' => true,
        'custom_roles' => true,
        'teams' => true,
        'automations' => true,
        'business_hours' => true,
        'identity_sources' => true
      },
      limits: {
        'users' => 50,
        'teams' => 50,
        'automations' => 50,
        'business_hour_groups' => 50,
        'identity_sources' => 50
      }
    )
  end

  let!(:subscription) { create(:subscription, account: account, plan: pro_plan, status: :active) }

  let(:conversations_only_role) do
    account.with_shard do
      create(:access_role,
        account: account,
        name: 'Conversations Only Agent',
        permissions: {
          'conversations' => { 'read' => true, 'write' => true }
        }
      )
    end
  end

  let(:automation_lead_role) do
    account.with_shard do
      create(:access_role,
        account: account,
        name: 'Automation Specialist',
        permissions: {
          'automations' => { 'read' => true, 'manage' => true },
          'teams' => { 'read' => true }
        }
      )
    end
  end

  before do
    set_subdomain(account.identifier)
  end

  describe 'Account Owner' do
    before do
      sign_in owner_user
    end

    it 'has unrestricted access to all dashboard areas by default' do
      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get teams_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get automations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get roles_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get business_hour_groups_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Non-owner Agent with no roles assigned' do
    before do
      sign_in agent_user
    end

    it 'is blocked from accessing restricted sections and receives not authorized flash error' do
      get teams_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get automations_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get roles_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get business_hour_groups_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')
    end
  end

  describe 'Non-owner Agent with Conversations Only Role' do
    before do
      agent_account_user.assign_roles([ conversations_only_role.id ])
      sign_in agent_user
    end

    it 'allows access to conversations index' do
      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end

    it 'blocks access to settings areas not granted in role' do
      get teams_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get automations_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get roles_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')

      get identity_sources_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')
    end
  end

  describe 'Non-owner Agent with Automation Specialist Role' do
    before do
      agent_account_user.assign_roles([ automation_lead_role.id ])
      sign_in agent_user
    end

    it 'allows access to automations index and teams index' do
      get automations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get teams_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end

    it 'allows creating automations' do
      expect {
        post automations_path(locale: :en), params: {
          automation: {
            name: 'Auto-Assign High Priority',
            automation_type: 'event_trigger',
            event_name: 'conversation.created',
            conditions: [].to_json,
            actions: [].to_json
          }
        }
      }.to change { account.automations.count }.by(1)

      expect(response).to redirect_to(automations_path)
    end

    it 'still blocks access to ungranted sections like roles management' do
      get roles_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')
    end
  end

  describe 'Multiple Roles and Dynamic Permission Updates' do
    before do
      sign_in agent_user
    end

    it 'merges permissions when multiple roles are assigned' do
      agent_account_user.assign_roles([ conversations_only_role.id, automation_lead_role.id ])

      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get automations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      get teams_path(locale: :en)
      expect(response).to have_http_status(:ok)

      # Still blocked from roles
      get roles_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')
    end

    it 'immediately denies access once a role is revoked' do
      # Initially granted automation lead
      agent_account_user.assign_roles([ automation_lead_role.id ])
      get automations_path(locale: :en)
      expect(response).to have_http_status(:ok)

      # Revoke automation lead and assign only conversations role
      agent_account_user.assign_roles([ conversations_only_role.id ])
      get automations_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq('You are not authorized to perform this action.')
    end
  end
end
