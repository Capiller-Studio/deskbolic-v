# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Roles and Permissions End-to-End Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Cyber Corp', identifier: 'cyber-corp') }
  let(:owner_user) { create(:user, confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  let(:agent_user) { create(:user, confirmed_at: Time.current) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

  let(:plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'roles' => true,
        'custom_roles' => true,
        'sla' => true,
        'csat' => true,
        'assignment_policies' => true,
        'email_templates' => true,
        'automations' => true
      },
      limits: {
        'users' => 50,
        'sla_policies' => 20,
        'assignment_policies' => 20,
        'csat_surveys' => 20,
        'email_templates' => 20,
        'automations' => 20
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
  end

  describe 'Custom Role Lifecycle in UI (Owner Flow)' do
    let(:role_name) { "Compliance Auditor #{SecureRandom.hex(4)}" }
    let(:updated_name) { "Compliance Officer #{SecureRandom.hex(4)}" }

    before do
      login_as(owner_user, scope: :user)
    end

    it 'creates a custom role, lists it in the roles grid, edits and deletes it' do
      # 1. Visit Roles page
      visit "#{Capybara.app_host}#{roles_path(locale: :en)}"
      expect(page).to have_current_path(%r{/roles})
      expect(page).to have_text(I18n.t('dashboard.roles.index.title', default: 'Roles & Permissions'))

      # 2. Click "Create Role"
      find('a.roles-primary-button', text: /Create Role/i).click
      expect(page).to have_current_path(%r{/roles/new})

      # 3. Enter role name and select a preset (e.g. Read Only)
      fill_in 'access_role[name]', with: role_name

      # Select Read Only preset
      find('.roles-preset-option', text: /Read Only/i).click

      # 4. Save Role
      find('button[type="submit"]').click

      # 5. Redirected to roles index and card is listed
      expect(page).to have_current_path(%r{/roles})
      expect(page).to have_text(role_name)
      expect(page).to have_text('CUSTOM')

      created_role = account.with_shard { Access::Role.find_by(name: role_name) }
      expect(created_role).to be_present
      expect(created_role.system_provided?).to be(false)

      # 6. Edit Role
      role_dom_id = ActionView::RecordIdentifier.dom_id(created_role)
      role_card = find("##{role_dom_id}")
      within(role_card) do
        find('details.roles-card-menu summary').click
        click_link 'Edit'
      end

      expect(page).to have_field('access_role[name]', with: role_name)
      fill_in 'access_role[name]', with: updated_name
      find('button[type="submit"]').click

      expect(page).to have_current_path(%r{/roles})
      expect(page).to have_text(updated_name)

      # 7. Delete Role
      updated_card = find("##{role_dom_id}")
      within(updated_card) do
        find('details.roles-card-menu summary').click
        page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
        find('a.roles-card-delete').click
      end

      expect(page).not_to have_selector("##{role_dom_id}")
      expect(account.with_shard { Access::Role.find_by(id: created_role.id) }).to be_nil
    end
  end

  describe 'Granular Permission Enforcement & Dynamic Elevation (Agent Flow)' do
    let(:restricted_role) do
      account.with_shard do
        create(:access_role,
          account: account,
          name: 'Frontline Agent',
          permissions: {
            'conversations' => { 'read' => true, 'write' => true }
          }
        )
      end
    end

    before do
      agent_account_user.assign_roles([restricted_role.id])
      login_as(agent_user, scope: :user)
    end

    it 'blocks restricted agent from unauthorized endpoints and unlocks access upon permission grant' do
      # 1. Agent can access conversations dashboard
      visit "#{Capybara.app_host}#{conversations_path(locale: :en)}"
      expect(page).to have_current_path(%r{/conversations})

      # 2. Agent is denied access to SLA Policies
      visit "#{Capybara.app_host}#{sla_policies_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 3. Agent is denied access to Assignment Policies
      visit "#{Capybara.app_host}#{assignment_policies_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 4. Agent is denied access to CSAT Surveys
      visit "#{Capybara.app_host}#{csat_surveys_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 5. Agent is denied access to Email Templates
      visit "#{Capybara.app_host}#{email_templates_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 6. Agent is denied access to Roles management
      visit "#{Capybara.app_host}#{roles_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 7. Admin dynamically elevates agent permissions for SLA & Assignment Policies
      account.with_shard do
        restricted_role.update!(
          permissions: {
            'conversations' => { 'read' => true, 'write' => true },
            'sla_policies' => { 'read' => true, 'manage' => true },
            'assignment_policies' => { 'read' => true, 'manage' => true }
          }
        )
      end

      # 8. Agent can now access SLA Policies
      visit "#{Capybara.app_host}#{sla_policies_path(locale: :en)}"
      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(I18n.t('dashboard.sla_policies.index.title', default: 'SLA Policies'))
      expect(page).not_to have_text('You are not authorized to perform this action.')

      # 9. Agent can now access Assignment Policies
      visit "#{Capybara.app_host}#{assignment_policies_path(locale: :en)}"
      expect(page).to have_current_path(%r{/assignment_policies})
      expect(page).to have_text(I18n.t('dashboard.assignment_policies.index.title', default: 'Assignment Policies'))
      expect(page).not_to have_text('You are not authorized to perform this action.')
    end
  end
end
