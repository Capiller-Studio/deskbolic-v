# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Granular Role-Based Action Permissions Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Secure Ops Inc', identifier: 'secure-ops') }
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
        'automations' => true,
        'email_templates' => true,
        'sla' => true
      },
      limits: {
        'users' => 50,
        'automations' => 50,
        'email_templates' => 50,
        'sla_policies' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  # Seed sample records so read-only views have content to display
  let!(:existing_automation) do
    account.with_shard do
      create(:automation,
        account: account,
        name: 'Initial Welcome Auto',
        automation_type: :event_trigger,
        event_name: 'conversation.created',
        conditions: {
          'operator' => 'AND',
          'groups' => [
            {
              'operator' => 'AND',
              'conditions' => [
                { 'attribute' => 'priority', 'operator' => 'equals', 'value' => 'medium' }
              ]
            }
          ]
        },
        actions: [
          { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } }
        ],
        status: :active
      )
    end
  end

  let!(:existing_email_template) do
    account.with_shard do
      create(:email_template,
        account: account,
        name: 'General FAQ Template',
        template_type: :conversation_reply,
        body: 'Hello {{customer.name}}'
      )
    end
  end

  let!(:existing_sla_policy) do
    account.with_shard do
      create(:sla_policy,
        account: account,
        name: 'Standard 24h SLA',
        description: 'Enterprise standard guarantee'
      )
    end
  end

  before do
    host_for_account(account)
  end

  context 'when user has READ-ONLY permissions for sections' do
    let(:read_only_role) do
      account.with_shard do
        create(:access_role,
          account: account,
          name: 'Auditor Read Only',
          permissions: {
            'conversations' => { 'read' => true, 'write' => true },
            'automations' => { 'read' => true },
            'email_templates' => { 'read' => true },
            'sla_policies' => { 'read' => true }
          }
        )
      end
    end

    before do
      agent_account_user.assign_roles([read_only_role.id])
      login_as(agent_user, scope: :user)
    end

    it 'allows viewing section indexes but strictly blocks mutating / create actions' do
      # 1. Automations Section: Can view index with content, blocked from /new
      visit "#{Capybara.app_host}#{automations_path(locale: :en)}"
      expect(page).to have_current_path(%r{/automations})
      expect(page).to have_text(I18n.t('dashboard.automations.index.title', default: 'Automations'))
      expect(page).to have_text('Initial Welcome Auto')

      # Attempting to visit /automations/new directly
      visit "#{Capybara.app_host}#{new_automation_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 2. Email Templates Section: Can view index with content, blocked from /new
      visit "#{Capybara.app_host}#{email_templates_path(locale: :en)}"
      expect(page).to have_current_path(%r{/email_templates})
      expect(page).to have_text(I18n.t('dashboard.email_templates.index.title', default: 'Email Templates'))
      expect(page).to have_text(/General FAQ Template/i)

      # Attempting to visit /email_templates/new directly
      visit "#{Capybara.app_host}#{new_email_template_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')

      # 3. SLA Policies Section: Can view index with content, blocked from /new
      visit "#{Capybara.app_host}#{sla_policies_path(locale: :en)}"
      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(I18n.t('dashboard.sla_policies.index.title', default: 'SLA Policies'))
      expect(page).to have_text('Standard 24h SLA')

      # Attempting to visit /sla_policies/new directly
      visit "#{Capybara.app_host}#{new_sla_policy_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')
    end
  end

  context 'when user has MANAGE permissions for sections' do
    let(:manage_role) do
      account.with_shard do
        create(:access_role,
          account: account,
          name: 'Section Manager',
          permissions: {
            'conversations' => { 'read' => true, 'write' => true },
            'automations' => { 'read' => true, 'manage' => true },
            'email_templates' => { 'read' => true, 'manage' => true },
            'sla_policies' => { 'read' => true, 'manage' => true }
          }
        )
      end
    end

    before do
      agent_account_user.assign_roles([manage_role.id])
      login_as(agent_user, scope: :user)
    end

    it 'allows accessing sections and performing mutating create actions' do
      # 1. Automations Section: Can access /automations/new and create automation
      auto_title = "Escalate High Priority #{SecureRandom.hex(4)}"
      visit "#{Capybara.app_host}#{new_automation_path(locale: :en)}"
      expect(page).to have_current_path(%r{/automations/new})
      expect(page).not_to have_text('You are not authorized to perform this action.')

      fill_in 'automation[name]', with: auto_title
      page.execute_script(<<~JS)
        const eventSelect = document.querySelector('select[name="automation[event_name]"]');
        if (eventSelect) {
          eventSelect.value = 'conversation.created';
          eventSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      find('button[form="automation-form"]').click
      expect(page).to have_current_path(%r{/automations})
      expect(page).to have_text(auto_title)

      # 2. Email Templates Section: Can access /email_templates/new and create template
      template_title = "VIP Support Greeting #{SecureRandom.hex(4)}"
      visit "#{Capybara.app_host}#{new_email_template_path(locale: :en)}"
      expect(page).to have_current_path(%r{/email_templates/new})
      expect(page).not_to have_text('You are not authorized to perform this action.')

      fill_in 'email_template[name]', with: template_title
      page.execute_script(<<~JS)
        const typeSelect = document.querySelector('select[name="email_template[template_type]"]');
        if (typeSelect) {
          typeSelect.value = 'conversation_reply';
          typeSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      find('button[form="new-email-template-form"]').click
      expect(page).to have_current_path(%r{/email_templates/[^/]+/edit})
      expect(page).to have_text(/#{template_title}/i)

      # 3. SLA Policies Section: Can access /sla_policies/new and create policy
      sla_title = "Gold SLA 4h #{SecureRandom.hex(4)}"
      visit "#{Capybara.app_host}#{new_sla_policy_path(locale: :en)}"
      expect(page).to have_current_path(%r{/sla_policies/new})
      expect(page).not_to have_text('You are not authorized to perform this action.')

      fill_in 'sla_policy[name]', with: sla_title
      fill_in 'sla_policy[description]', with: 'High-priority guarantee'
      fill_in 'sla_policy[initial_response_value]', with: '15'
      fill_in 'sla_policy[response_value]', with: '2'
      fill_in 'sla_policy[resolution_value]', with: '24'
      find('button[type="submit"]').click

      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(sla_title)
    end
  end
end
