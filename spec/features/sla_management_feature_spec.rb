# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SLA Management & Lifecycle Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'SLA Corp', identifier: 'sla-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'sla' => true,
        'business_hours' => true,
        'assignment_policies' => true,
        'roles' => true
      },
      limits: {
        'sla_policies' => 20,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:inbox) { create(:inbox, account: account, name: "Priority Inbox #{SecureRandom.hex(3)}") }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'SLA Policies Administration UI/UX' do
    let(:policy_name) { "Gold Tier SLA #{SecureRandom.hex(4)}" }
    let(:updated_name) { "Gold Tier SLA Updated #{SecureRandom.hex(4)}" }

    it 'creates a new SLA policy with target metrics, lists it on index, and allows editing & deletion' do
      # 1. Visit SLA Policies Index
      visit "#{Capybara.app_host}#{sla_policies_path(locale: :en)}"
      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(I18n.t('dashboard.sla_policies.index.title', default: 'SLA Policies'))

      # 2. Click "+ New Policy"
      find('#new-sla-policy').click
      expect(page).to have_current_path(%r{/sla_policies/new})

      # 3. Fill in Details
      fill_in 'sla_policy[name]', with: policy_name
      fill_in 'sla_policy[description]', with: 'High-priority enterprise customer guarantee'

      # Target inputs
      fill_in 'sla_policy[initial_response_value]', with: '15'
      fill_in 'sla_policy[response_value]', with: '2'
      fill_in 'sla_policy[resolution_value]', with: '24'

      page.execute_script(<<~JS)
        const respUnit = document.querySelector('select[name="sla_policy[response_unit]"]');
        if (respUnit) {
          respUnit.value = 'hours';
          respUnit.dispatchEvent(new Event('change', { bubbles: true }));
        }
        const resUnit = document.querySelector('select[name="sla_policy[resolution_unit]"]');
        if (resUnit) {
          resUnit.value = 'hours';
          resUnit.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      # Select inbox
      within('.ap-inboxes-card') do
        find('.choices').click
        find('.choices__item--choice', text: inbox.name).click
      end

      # 4. Save Policy
      find('button[form="sla-policy-form"]').click

      # 5. Redirected to index and policy card displays metrics
      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(policy_name)
      expect(page).to have_text('15m')
      expect(page).to have_text('2h')
      expect(page).to have_text('1d')

      created_policy = account.with_shard { SlaPolicy.find_by(name: policy_name) }
      expect(created_policy).to be_present
      expect(created_policy.initial_response_time_limit).to eq(900.0) # 15 minutes
      expect(created_policy.response_time_limit).to eq(7200.0) # 2 hours
      expect(created_policy.resolution_time_limit).to eq(86400.0) # 24 hours
      expect(created_policy.inboxes).to include(inbox)

      # 6. Edit Policy via card menu
      policy_card = find("#sla_policy_#{created_policy.id}")
      within(policy_card) do
        find('details.ai-agent-card-menu summary').click
        click_link 'Edit'
      end

      expect(page).to have_field('sla_policy[name]', with: policy_name)
      fill_in 'sla_policy[name]', with: updated_name
      fill_in 'sla_policy[initial_response_value]', with: '30'

      find('button[form="sla-policy-form"]').click

      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(updated_name)
      expect(page).to have_text('30m')

      # 7. Delete Policy
      updated_card = find("#sla_policy_#{created_policy.id}")
      within(updated_card) do
        find('details.ai-agent-card-menu summary').click
        page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
        click_button 'Delete'
      end

      expect(page).not_to have_selector("#sla_policy_#{created_policy.id}")
      expect(account.with_shard { SlaPolicy.find_by(id: created_policy.id) }).to be_nil
    end

    it 'handles validation errors when required name is missing' do
      visit "#{Capybara.app_host}#{new_sla_policy_path(locale: :en)}"

      # Attempt submit without name by bypassing browser HTML5 validation
      page.execute_script("document.querySelector('#sla-policy-name').removeAttribute('required')")
      find('button[form="sla-policy-form"]').click

      expect(page).to have_selector('.ui-field-control--invalid')
    end
  end

  describe 'Conversation SLA Badges & Inspection UI/UX' do
    let(:sla_name) { "Platinum SLA #{SecureRandom.hex(4)}" }
    let!(:sla_policy) do
      account.with_shard do
        create(:sla_policy,
          account: account,
          name: sla_name,
          initial_response_time_limit: 1800, # 30 min
          resolution_time_limit: 86400 # 24 hours
        )
      end
    end

    let!(:customer) do
      account.with_shard do
        create(:customer, account: account, email: 'vip@client.com', first_name: 'VIP', last_name: 'Customer')
      end
    end

    let!(:conversation) do
      account.with_shard do
        conv = create(:conversation, account: account, inbox: inbox, status: :active)
        create(:conversation_member, conversation: conv, member: customer)
        conv
      end
    end

    it 'displays On track badge and target details in conversation inspector drawer' do
      account.with_shard do
        conv_sla = conversation.conversation_slas.find_or_initialize_by(sla_policy: sla_policy)
        conv_sla.update!(
          account: account,
          status: :pending,
          target_first_response_at: 20.minutes.from_now,
          target_resolution_at: 20.hours.from_now
        )
      end

      visit "#{Capybara.app_host}#{conversation_path(conversation, locale: :en)}"
      expect(page).to have_text('VIP Customer')

      # Verify SLA Status badge is "On track" in the inspector sidebar
      within('.conversation-inspector') do
        expect(page).to have_text(/SLA Status/i)
        expect(page).to have_text('On track')

        # Click accordion to expand details
        find('button.inspector-accordion', text: /SLA Status/i).click

        expect(page).to have_text(sla_name)
        expect(page).to have_text('First Response Target')
        expect(page).to have_text('Resolution Target')
      end
    end

    it 'displays Breached badge when an SLA deadline is missed' do
      account.with_shard do
        conv_sla = conversation.conversation_slas.find_or_initialize_by(sla_policy: sla_policy)
        conv_sla.update!(
          account: account,
          status: :failed,
          target_first_response_at: 1.hour.ago,
          target_resolution_at: 2.hours.ago
        )
      end

      visit "#{Capybara.app_host}#{conversation_path(conversation, locale: :en)}"
      expect(page).to have_text('VIP Customer')

      within('.conversation-inspector') do
        expect(page).to have_text(/SLA Status/i)
        expect(page).to have_text('Breached')
        expect(page).to have_selector('small.text-danger')
      end
    end
  end
end
