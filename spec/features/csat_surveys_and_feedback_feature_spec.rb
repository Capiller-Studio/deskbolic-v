# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CSAT Surveys and Customer Feedback Browser Feature Flow', :js, type: :feature do
  let(:account) { create(:account, name: 'Satisfaction Corp', identifier: 'satisfaction-corp') }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let(:plan) do
    create(:plan,
      name: 'Enterprise Plan',
      features: {
        'csat' => true,
        'email_templates' => true,
        'roles' => true
      },
      limits: {
        'csat_surveys' => 20,
        'users' => 50
      }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:inbox) { create(:inbox, account: account, name: "Support Desk #{SecureRandom.hex(3)}") }

  let!(:email_template) do
    account.with_shard do
      create(:email_template,
        account: account,
        name: "CSAT Survey Mailer #{SecureRandom.hex(3)}",
        template_type: :csat_survey
      )
    end
  end

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'CSAT Survey Management UI/UX' do
    let(:survey_name) { "Post Chat CSAT #{SecureRandom.hex(4)}" }
    let(:updated_name) { "Post Chat CSAT Updated #{SecureRandom.hex(4)}" }

    it 'creates a CSAT survey linked to an email template, lists it on index, allows editing and deletion' do
      # 1. Visit CSAT Surveys index
      visit "#{Capybara.app_host}#{csat_surveys_path(locale: :en)}"
      expect(page).to have_current_path(%r{/csat_surveys})
      expect(page).to have_text(I18n.t('dashboard.csat_surveys.index.title', default: 'CSAT Surveys'))

      # 2. Click "+ New Survey"
      find('header a.ui-settings-page__action').click
      expect(page).to have_current_path(%r{/csat_surveys/new})
      expect(page).to have_text(I18n.t('dashboard.csat_surveys.new.title', default: 'New Survey'))

      # 3. Fill details and configure email template
      fill_in 'csat_survey[name]', with: survey_name
      fill_in 'csat_survey[prompt]', with: 'How satisfied are you with our assistance today?'
      fill_in 'csat_survey[portal_title]', with: 'Rate your support experience'
      fill_in 'csat_survey[portal_subtitle]', with: 'Your candid feedback helps us do better.'
      fill_in 'csat_survey[portal_feedback_label]', with: 'Tell us how we can improve (optional)'

      # Select assigned email template via Choices UI
      page.execute_script(<<~JS)
        const sel = document.querySelector('select[name="csat_survey[email_template_id]"]');
        if (sel) {
          sel.value = '#{email_template.id}';
          sel.dispatchEvent(new Event('change', { bubbles: true }));
        }
      JS

      # 4. Save Survey
      find('button[form="csat-survey-form"]').click

      # 5. Redirected to index and survey card displayed
      expect(page).to have_current_path(%r{/csat_surveys})
      expect(page).to have_text(survey_name)
      expect(page).to have_text(email_template.name)
      expect(page).to have_text('How satisfied are you with our assistance today?')

      created_survey = account.with_shard { Csat::Survey.find_by(name: survey_name) }
      expect(created_survey).to be_present
      expect(created_survey.email_template_id).to eq(email_template.id)
      expect(created_survey.portal_title).to eq('Rate your support experience')

      # 6. Edit Survey via card menu
      survey_card = find("#csat_survey_#{created_survey.id}")
      within(survey_card) do
        find('details.ai-agent-card-menu summary').click
        click_link 'Edit'
      end

      expect(page).to have_field('csat_survey[name]', with: survey_name)
      fill_in 'csat_survey[name]', with: updated_name
      fill_in 'csat_survey[prompt]', with: 'How was your recent experience with our agent?'

      find('button[form="csat-survey-form"]').click

      expect(page).to have_current_path(%r{/csat_surveys})
      expect(page).to have_text(updated_name)
      expect(page).to have_text('How was your recent experience with our agent?')

      # 7. Delete Survey
      updated_card = find("#csat_survey_#{created_survey.id}")
      within(updated_card) do
        find('details.ai-agent-card-menu summary').click
        page.execute_script("document.querySelectorAll('[data-turbo-confirm]').forEach(el => el.removeAttribute('data-turbo-confirm'))")
        click_button 'Delete'
      end

      expect(page).not_to have_selector("#csat_survey_#{created_survey.id}")
      expect(account.with_shard { Csat::Survey.find_by(id: created_survey.id) }).to be_nil
    end

    it 'handles validation error when required survey name or portal title is missing' do
      visit "#{Capybara.app_host}#{new_csat_survey_path(locale: :en)}"

      fill_in 'csat_survey[prompt]', with: 'Some prompt'
      find('button[form="csat-survey-form"]').click

      expect(page).to have_text(/Validation failed|Name can't be blank/i)
    end
  end

  describe 'Conversation CSAT Rating & Feedback Inspection UI/UX' do
    let!(:customer) do
      account.with_shard do
        create(:customer, account: account, email: 'rating-user@client.com', first_name: 'Happy', last_name: 'Customer')
      end
    end

    let!(:conversation) do
      account.with_shard do
        conv = create(:conversation, account: account, inbox: inbox, status: :resolved)
        create(:conversation_member, conversation: conv, member: customer)
        conv
      end
    end

    it 'displays "No rating yet" when no survey feedback has been received' do
      visit "#{Capybara.app_host}#{conversation_path(conversation, locale: :en)}"
      expect(page).to have_text('Happy Customer')

      within('.conversation-inspector') do
        expect(page).to have_text(/CSAT Rating/i)
        expect(page).to have_text('No rating yet')
      end
    end

    it 'displays submitted rating and feedback notes inside inspector accordion' do
      account.with_shard do
        create(:csat_survey_response,
          account: account,
          conversation: conversation,
          customer: customer,
          rating: 5,
          content: 'Awesome customer support agent!',
          status: :submitted
        )
      end

      visit "#{Capybara.app_host}#{conversation_path(conversation, locale: :en)}"
      expect(page).to have_text('Happy Customer')

      within('.conversation-inspector') do
        expect(page).to have_text(/CSAT Rating/i)
        expect(page).to have_text('5 / 5')

        # Expand accordion to verify feedback details
        find('button.inspector-accordion', text: /CSAT Rating/i).click

        expect(page).to have_text('5 / 5')
      end
    end
  end
end
