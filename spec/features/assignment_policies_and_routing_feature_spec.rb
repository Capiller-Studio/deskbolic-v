# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment Policies and Routing Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Routing Corp', identifier: 'routing-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'assignment_policies' => true,
        'business_hours' => true,
        'roles' => true
      },
      limits: {
        'assignment_policies' => 20,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:inbox) { create(:inbox, account: account, name: "VIP Inbound #{SecureRandom.hex(3)}") }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'Assignment Policies Administration UI/UX' do
    let(:rr_name) { "Round Robin Policy #{SecureRandom.hex(4)}" }
    let(:lb_name) { "Load Balanced Policy #{SecureRandom.hex(4)}" }

    it 'creates a policy with strategy card selection, capacity limit, and options, then edits and deletes it' do
      # 1. Visit Assignment Policies Index
      visit "#{Capybara.app_host}#{assignment_policies_path(locale: :en)}"
      expect(page).to have_current_path(%r{/assignment_policies})
      expect(page).to have_text(I18n.t('dashboard.assignment_policies.index.title', default: 'Assignment Policies'))

      # 2. Click "+ New Policy"
      find('#new-assignment-policy').click
      expect(page).to have_current_path(%r{/assignment_policies/new})

      # 3. Fill details
      fill_in 'assignment_policy[name]', with: rr_name
      fill_in 'assignment_policy[description]', with: 'Even distribution among active tier-1 agents'

      # Select Round Robin strategy card
      find('#strategy-round_robin').click

      # Set capacity limit
      fill_in 'assignment_policy[max_conversations_per_agent]', with: '5'

      # Toggle options
      find('label[for="policy-prioritize"]').click

      # 4. Save Policy
      find('button[form="assignment-policy-form"]').click

      # 5. Redirected to index and card displayed
      expect(page).to have_current_path(%r{/assignment_policies})
      expect(page).to have_text(rr_name)
      expect(page).to have_text('Round Robin')
      expect(page).to have_text('5')

      created_policy = account.with_shard { AssignmentPolicy.find_by(name: rr_name) }
      expect(created_policy).to be_present
      expect(created_policy.strategy).to eq('round_robin')
      expect(created_policy.max_conversations_per_agent).to eq(5)
      expect(created_policy.prioritize_by_conversation_priority?).to be(true)

      # 6. Edit Policy via card menu
      policy_card = find("#policy_#{created_policy.id}")
      within(policy_card) do
        find('details.ai-agent-card-menu summary').click
        click_link 'Edit'
      end

      expect(page).to have_field('assignment_policy[name]', with: rr_name)
      fill_in 'assignment_policy[max_conversations_per_agent]', with: '8'

      # Switch strategy to Load Balanced
      find('#strategy-load_balanced').click

      find('button[form="assignment-policy-form"]').click

      expect(page).to have_current_path(%r{/assignment_policies})
      expect(page).to have_text('Load Balanced')
      expect(page).to have_text('8')

      expect(created_policy.reload.strategy).to eq('load_balanced')
      expect(created_policy.max_conversations_per_agent).to eq(8)

      # 7. Toggle status (Deactivate / Activate)
      card_to_toggle = find("#policy_#{created_policy.id}")
      within(card_to_toggle) do
        find('details.ai-agent-card-menu summary').click
        click_link 'Deactivate'
      end

      # Wait for Turbo Stream to update the card and show Inactive status
      expect(page).to have_text('Inactive')
      expect(created_policy.reload.status).to eq('inactive')

      # 8. Delete Policy
      card_to_delete = find("#policy_#{created_policy.id}")
      within(card_to_delete) do
        find('details.ai-agent-card-menu summary').click
        page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
        click_button 'Delete'
      end

      expect(page).not_to have_selector("#policy_#{created_policy.id}")
      expect(account.with_shard { AssignmentPolicy.find_by(id: created_policy.id) }).to be_nil
    end

    it 'handles validation error when required policy name is missing' do
      visit "#{Capybara.app_host}#{new_assignment_policy_path(locale: :en)}"

      # Trigger client-side validation
      find('button[form="assignment-policy-form"]').click
      expect(page).to have_selector('form.was-validated')

      # Also test server-side validation by bypassing checkValidity
      page.execute_script("document.querySelector('#policy-name').removeAttribute('required')")
      find('button[form="assignment-policy-form"]').click
      expect(page).to have_selector('.ui-field-control--invalid')
    end
  end

  describe 'Strategy Filtering Tabs UI/UX' do
    let(:rr_name) { "Tier1 Round Robin #{SecureRandom.hex(4)}" }
    let(:lb_name) { "Tier2 Load Balanced #{SecureRandom.hex(4)}" }

    let!(:rr_policy) do
      account.with_shard do
        create(:assignment_policy,
          account: account,
          name: rr_name,
          strategy: :round_robin,
          status: :active
        )
      end
    end

    let!(:lb_policy) do
      account.with_shard do
        create(:assignment_policy,
          account: account,
          name: lb_name,
          strategy: :load_balanced,
          status: :active
        )
      end
    end

    it 'filters policies according to selected strategy tab' do
      visit "#{Capybara.app_host}#{assignment_policies_path(locale: :en)}"

      # All tab shows both
      expect(page).to have_text(rr_name)
      expect(page).to have_text(lb_name)

      # Click Round Robin tab
      find('.ui-filter-tabs__tab', text: 'Round Robin').click
      expect(page).to have_text(rr_name)
      expect(page).not_to have_text(lb_name)

      # Click Load Balanced tab
      find('.ui-filter-tabs__tab', text: 'Load Balanced').click
      expect(page).to have_text(lb_name)
      expect(page).not_to have_text(rr_name)
    end
  end
end
