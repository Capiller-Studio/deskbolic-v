# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Automations and Macros Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Automate Corp', identifier: 'automate-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Parabolic Plan',
      features: {
        'automations' => true,
        'roles' => true,
        'custom_roles' => true
      },
      limits: {
        'automations' => 50,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'Automations Management UI/UX' do
    it 'creates a new automation rule, displays it on the index, and allows editing' do
      # 1. Visit automations index
      visit "#{Capybara.app_host}#{automations_path(locale: :en)}"
      expect(page).to have_current_path(%r{/automations})
      expect(page).to have_text(I18n.t('dashboard.automations.index.title', default: 'Automations'))

      # 2. Click "+ New Automation"
      find('a.ui-settings-page__action').click
      expect(page).to have_current_path(%r{/automations/new})
      expect(page).to have_text(I18n.t('dashboard.automations.new.title', default: 'New Automation'))

      # 3. Fill in details
      fill_in 'automation[name]', with: 'VIP Auto Escalation'
      fill_in 'automation[description]', with: 'Automatically prioritizes VIP conversations'

      # Select event via JS to work seamlessly with Choices.js
      page.execute_script(<<~JS)
        const sel = document.querySelector('select[name="automation[event_name]"]');
        if (sel) {
          sel.value = 'conversation.created';
          sel.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      # 4. Save automation
      find('button[form="automation-form"]').click

      # 5. Redirected to index with new rule displayed
      expect(page).to have_current_path(%r{/automations})
      expect(page).to have_text('VIP Auto Escalation')

      # 6. Edit the automation
      find('summary.auto-card-menu__trigger').click
      click_link 'Edit'
      expect(page).to have_field('automation[name]', with: 'VIP Auto Escalation')

      fill_in 'automation[name]', with: 'VIP Auto Escalation Updated'
      find('button[form="automation-form"]').click

      expect(page).to have_current_path(%r{/automations})
      expect(page).to have_text('VIP Auto Escalation Updated')
    end
  end

  describe 'Macros Management UI/UX' do
    it 'creates a new macro, filters by tabs, and lists in the table' do
      # 1. Visit macros index
      visit "#{Capybara.app_host}#{macros_path(locale: :en)}"
      expect(page).to have_current_path(%r{/macros})
      expect(page).to have_text('Macros')

      # 2. Click "+ New Macro"
      find('a.ui-settings-page__action').click
      expect(page).to have_current_path(%r{/macros/new})

      # 3. Fill macro form
      fill_in 'macro[name]', with: 'Quick Resolution Template'
      page.execute_script(<<~JS)
        const sel = document.querySelector('select[name="macro[visibility]"]');
        if (sel) {
          sel.value = 'account_wide';
          sel.dispatchEvent(new Event('change', { bubbles: true }));
        }
        const actionType = document.querySelector('[data-action-type]');
        if (actionType) {
          actionType.value = 'set_status';
        }
        const paramsContainer = document.querySelector('[data-action-params]');
        if (paramsContainer) {
          paramsContainer.innerHTML = '<select data-action-param="status"><option value="resolved" selected>Resolved</option></select>';
        }
      JS

      # Save macro
      find('button.ui-btn-primary[type="submit"]').click

      # 4. Redirected to index and macro listed
      expect(page).to have_current_path(%r{/macros})
      expect(page).to have_text('Quick Resolution Template')
      expect(page).to have_text('Account-wide')

      # 5. Filter tabs
      click_link 'Personal'
      expect(page).not_to have_text('Quick Resolution Template')

      click_link 'Account-wide'
      expect(page).to have_text('Quick Resolution Template')
    end
  end

  describe 'RBAC UI/UX Restriction' do
    let(:agent_user) { create(:user, confirmed_at: Time.current) }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }
    let(:restricted_role) do
      account.with_shard do
        create(:access_role,
          account: account,
          name: 'Restricted Support Agent',
          permissions: { 'conversations' => { 'read' => true } }
        )
      end
    end

    before do
      agent_account_user.assign_roles([ restricted_role.id ])
      login_as(agent_user, scope: :user)
    end

    it 'blocks restricted agent from accessing automations and displays authorization alert' do
      visit "#{Capybara.app_host}#{automations_path(locale: :en)}"
      expect(page).to have_text('You are not authorized to perform this action.')
    end
  end
end
