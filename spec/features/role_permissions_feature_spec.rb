# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Role Permissions Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Shield Corp', identifier: 'shield-corp') }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  let(:agent_user) { create(:user, confirmed_at: Time.current) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

  let(:plan) do
    create(:plan,
      name: 'Parabolic Plan',
      features: {
        'roles' => true,
        'custom_roles' => true,
        'teams' => true,
        'automations' => true,
        'identity_sources' => true
      },
      limits: {
        'users' => 50,
        'teams' => 50,
        'automations' => 50
      }
    )
  end

  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let(:restricted_role) do
    account.with_shard do
      create(:access_role,
        account: account,
        name: 'Restricted Agent',
        permissions: {
          'conversations' => { 'read' => true, 'write' => true }
        }
      )
    end
  end

  before do
    host_for_account(account)
  end

  it 'enforces role permissions in browser, blocking unauthorized actions and allowing authorized flows' do
    # 1. Assign Restricted Agent role to agent
    agent_account_user.assign_roles([ restricted_role.id ])

    # 2. Agent logs into the browser
    login_as(agent_user, scope: :user)

    # 3. Agent can access conversations dashboard
    visit "#{Capybara.app_host}#{conversations_path(locale: :en)}"
    expect(page).to have_current_path(%r{/conversations})

    # 4. Agent attempts to directly access restricted settings (Automations)
    visit "#{Capybara.app_host}#{automations_path(locale: :en)}"
    expect(page).to have_text('You are not authorized to perform this action.')

    # 5. Agent attempts to access Roles management
    visit "#{Capybara.app_host}#{roles_path(locale: :en)}"
    expect(page).to have_text('You are not authorized to perform this action.')

    # 6. Admin elevates permissions by updating the role to include automations access
    account.with_shard do
      restricted_role.update!(
        permissions: {
          'conversations' => { 'read' => true, 'write' => true },
          'automations' => { 'read' => true, 'manage' => true }
        }
      )
    end

    # 7. Agent revisits automations page in browser
    visit "#{Capybara.app_host}#{automations_path(locale: :en)}"
    expect(page).to have_current_path(%r{/automations})
    expect(page).to have_text(I18n.t('dashboard.automations.index.title', default: 'Automations'))
    expect(page).to have_no_text('You are not authorized to perform this action.')
    find('a.ui-settings-page__action').click
    expect(page).to have_current_path(%r{/automations/new})
    expect(page).to have_text(I18n.t('dashboard.automations.new.title', default: 'New Automation'))
  end
end
