# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Business Hours and Modules Integration Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Schedule Corp', identifier: 'schedule-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Parabolic Plan',
      features: {
        'business_hours' => true,
        'sla' => true,
        'assignment_policies' => true,
        'roles' => true
      },
      limits: {
        'business_hour_groups' => 20,
        'sla_policies' => 20,
        'assignment_policies' => 20,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'Business Hours Management UI/UX' do
    it 'creates a weekly business hours schedule, lists it on index, and allows editing' do
      # 1. Visit business hours index
      visit "#{Capybara.app_host}#{business_hour_groups_path(locale: :en)}"
      expect(page).to have_current_path(%r{/business_hours})
      expect(page).to have_text(I18n.t('dashboard.business_hour_groups.index.title', default: 'Business Hours'))

      # 2. Click "+ New Business Hours" in header
      find('header a.ui-settings-page__action').click
      expect(page).to have_current_path(%r{/business_hours/new})
      expect(page).to have_text(I18n.t('dashboard.business_hour_groups.new.title', default: 'New Business Hours'))

      # 3. Fill details and timezone
      fill_in 'business_hour_group[name]', with: 'Americas Operations Hours'
      fill_in 'business_hour_group[description]', with: 'Mon-Fri 9am to 5pm EST schedule'

      page.execute_script(<<~JS)
        const tzSelect = document.querySelector('select[name="business_hour_group[timezone]"]');
        if (tzSelect) {
          tzSelect.value = 'Eastern Time (US & Canada)';
          tzSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
        document.querySelectorAll('.bh-time-input').forEach((input, i) => {
          input.value = (i % 2 === 0 ? '09:00' : '17:00');
          input.dispatchEvent(new Event('input', { bubbles: true }));
        });
      JS

      # 4. Save business hours
      find('button[form="business-hour-group-form"]').click

      # 5. Redirected to index and schedule listed
      expect(page).to have_current_path(%r{/business_hours})
      expect(page).to have_text('Americas Operations Hours')
      expect(page).to have_text('Eastern Time (US & Canada)')

      # 6. Edit business hours
      find('details.bh-card-menu summary').click
      click_link 'Edit'
      expect(page).to have_field('business_hour_group[name]', with: 'Americas Operations Hours')

      fill_in 'business_hour_group[name]', with: 'Americas Operations Hours Updated'
      find('button[form="business-hour-group-form"]').click

      expect(page).to have_current_path(%r{/business_hours})
      expect(page).to have_text('Americas Operations Hours Updated')
    end
  end

  describe 'Module Integration in UI: SLA Policies & Assignment Policies' do
    let!(:bh_group) do
      account.with_shard do
        create(:business_hour_group,
          account: account,
          name: 'Core Support Shift',
          timezone: 'Eastern Time (US & Canada)'
        )
      end
    end

    let(:sla_name) { "Working Hours SLA #{SecureRandom.hex(4)}" }
    let(:policy_name) { "Day Shift Routing #{SecureRandom.hex(4)}" }

    it 'allows linking business hour group inside SLA policy builder form' do
      visit "#{Capybara.app_host}#{new_sla_policy_path(locale: :en)}"
      expect(page).to have_current_path(%r{/sla_policies/new})

      fill_in 'sla_policy[name]', with: sla_name

      # Toggle During Working Hours
      find('label[for="policy-bh-toggle"]').click

      # Select business hours schedule via Choices UI
      within('.ap-conditional-field') do
        find('.choices').click
        find('.choices__item--choice', text: 'Core Support Shift').click
      end

      # Save policy
      find('button[form="sla-policy-form"]').click

      expect(page).to have_current_path(%r{/sla_policies})
      expect(page).to have_text(sla_name)

      created_sla = account.with_shard { SlaPolicy.find_by(name: sla_name) }
      expect(created_sla.during_working_hours?).to be(true)
      expect(created_sla.business_hour_group_id).to eq(bh_group.id)
    end

    it 'allows linking business hour group inside Assignment policy builder form' do
      visit "#{Capybara.app_host}#{new_assignment_policy_path(locale: :en)}"
      expect(page).to have_current_path(%r{/assignment_policies/new})

      fill_in 'assignment_policy[name]', with: policy_name

      # Toggle Respect Business Hours
      find('label[for="policy-bh-toggle"]').click

      # Select schedule via Choices UI
      within('.ap-conditional-field') do
        find('.choices').click
        find('.choices__item--choice', text: 'Core Support Shift').click
      end

      # Save policy
      find('button[form="assignment-policy-form"]').click

      expect(page).to have_current_path(%r{/assignment_policies})
      expect(page).to have_text(policy_name)

      created_policy = account.with_shard { AssignmentPolicy.find_by(name: policy_name) }
      expect(created_policy.respect_business_hours?).to be(true)
      expect(created_policy.business_hour_group_id).to eq(bh_group.id)
    end
  end
end
