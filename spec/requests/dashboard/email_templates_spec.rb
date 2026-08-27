# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::EmailTemplates', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'email_templates' => true }, limits: { 'email_templates' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in(user)
  end

  describe 'GET /email_templates' do
    it 'renders the email templates list successfully' do
      get email_templates_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /email_templates/new' do
    it 'renders the new email template form' do
      get new_email_template_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /email_templates' do
    it 'creates a new template and redirects to edit' do
      account.with_shard do
        expect do
          post email_templates_path, params: {
            email_template: {
              name: 'Custom Order Confirmation',
              template_type: 'conversation_reply'
            }
          }
        end.to change(EmailTemplate, :count).by(1)

        template = account.email_templates.find_by(name: 'Custom Order Confirmation')
        expect(response).to redirect_to(edit_email_template_path(id: template.id))
        expect(template.translations.pluck(:locale)).to include('en')
      end
    end
  end

  describe 'GET /email_templates/:id/edit' do
    it 'renders the editor for the template in requested locale' do
      account.with_shard do
        template = EmailTemplates::Creator.call(
          account: account,
          name: 'Feedback Survey',
          template_type: 'csat_survey'
        )

        get edit_email_template_path(id: template.id, template_locale: 'en')
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
