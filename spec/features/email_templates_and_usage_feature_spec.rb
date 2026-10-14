# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email Templates and Integrations Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Mailer Corp', identifier: 'mailer-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'email_templates' => true,
        'csat' => true,
        'automations' => true,
        'roles' => true
      },
      limits: {
        'email_templates' => 20,
        'csat_surveys' => 20,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'Email Template Creation & Visual Builder UI/UX' do
    let(:template_name) { "Agent Reply Theme #{SecureRandom.hex(4)}" }

    it 'creates a template, opens builder with Liquid variables drawer, and lists on index' do
      # 1. Visit Email Templates index
      visit "#{Capybara.app_host}#{email_templates_path(locale: :en)}"
      expect(page).to have_current_path(%r{/email_templates})
      expect(page).to have_text(I18n.t('dashboard.email_templates.index.title', default: 'Email Templates'))

      # 2. Click "Create Template" button
      find('header a.ui-settings-page__action').click
      expect(page).to have_current_path(%r{/email_templates/new})

      # 3. Fill template details
      fill_in 'email_template[name]', with: template_name

      # Select template_type (conversation_reply)
      page.execute_script(<<~JS)
        const typeSelect = document.querySelector('select[name="email_template[template_type]"]');
        if (typeSelect) {
          typeSelect.value = 'conversation_reply';
          typeSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      # 4. Submit form
      find('button[form="new-email-template-form"]').click

      # 5. Redirected to Email Builder editor
      expect(page).to have_current_path(%r{/email_templates/[\w-]+/edit})
      expect(page).to have_text(template_name.titleize)
      expect(page).to have_selector('#eb-save-btn')

      # 6. Open Variables panel in builder sidebar
      find('button.eb-sidebar__tab[data-tab="variables"]').click
      expect(page).to have_selector('.eb-sidebar__panel--active[data-panel="variables"]')
      expect(page).to have_selector('.eb-variables')

      # 7. Back to index and verify template appears in grid
      visit "#{Capybara.app_host}#{email_templates_path(locale: :en)}"
      expect(page).to have_text(template_name.titleize)

      # 8. Delete template from index
      created_template = account.with_shard { EmailTemplate.find_by(name: template_name) }
      expect(created_template).to be_present

      delete_btn = find('a.email-template-delete')
      page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
      delete_btn.click

      expect(page).not_to have_text(template_name.titleize)
      expect(account.with_shard { EmailTemplate.find_by(id: created_template.id) }).to be_nil
    end

    it 'handles validation error when template name is missing' do
      visit "#{Capybara.app_host}#{new_email_template_path(locale: :en)}"

      # Remove browser required attribute and submit empty
      page.execute_script("document.querySelector('input[name=\"email_template[name]\"]').removeAttribute('required')")
      find('button[form="new-email-template-form"]').click

      expect(page).to have_text(/Validation failed|can't be blank/i)
    end
  end

  describe 'Module Usage: Email Templates inside CSAT Surveys UI' do
    let(:csat_template_name) { "CSAT Rating Notification #{SecureRandom.hex(4)}" }
    let!(:csat_template) do
      account.with_shard do
        create(:email_template,
          account: account,
          name: csat_template_name,
          template_type: :csat_survey
        )
      end
    end

    it 'populates the assigned email template dropdown inside CSAT survey builder' do
      visit "#{Capybara.app_host}#{new_csat_survey_path(locale: :en)}"
      expect(page).to have_current_path(%r{/csat_surveys/new})

      # Verify template option is present in the select options
      template_options = page.all('#csat-survey-email-template option', visible: :all).map { |o| o.text(:all) }
      expect(template_options).to include(csat_template_name)
    end
  end
end
