# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::CsatSurveys', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'csat' => true, 'custom_csat' => true, 'roles' => true },
      limits: { 'csat_surveys' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:csat_survey) { account.with_shard { create(:csat_survey, account: account, name: 'General Support Survey') } }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /csat_surveys' do
    it 'renders the CSAT surveys index page' do
      csat_survey
      get csat_surveys_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('General Support Survey')
    end

    it 'supports non-English locales' do
      get csat_surveys_path(locale: :fr)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /csat_surveys/new' do
    it 'renders the new survey form' do
      get new_csat_survey_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('csat_survey[name]')
    end
  end

  describe 'POST /csat_surveys' do
    it 'creates a CSAT survey successfully' do
      expect {
        post csat_surveys_path(locale: :en), params: {
          csat_survey: {
            name: 'Post-Resolution CSAT',
            prompt: 'How satisfied were you with our resolution?'
          }
        }
      }.to change { account.with_shard { Csat::Survey.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(csat_surveys_path)
      created = account.with_shard { Csat::Survey.where(account_id: account.id).find_by(name: 'Post-Resolution CSAT') }
      expect(created).to be_present
      expect(created.prompt).to eq('How satisfied were you with our resolution?')
    end

    it 'renders new with unprocessable entity on validation failure' do
      post csat_surveys_path(locale: :en), params: {
        csat_survey: { name: '' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /csat_surveys/:id/edit' do
    it 'renders the edit survey form' do
      get edit_csat_survey_path(id: csat_survey.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('General Support Survey')
    end
  end

  describe 'PATCH /csat_surveys/:id' do
    it 'updates survey attributes and respects survey_locale' do
      patch csat_survey_path(id: csat_survey.id, locale: :en), params: {
        survey_locale: 'en',
        csat_survey: {
          name: 'Updated CSAT Survey Name',
          prompt: 'How was your experience today?'
        }
      }
      expect(response).to redirect_to(csat_surveys_path)
      account.with_shard do
        csat_survey.reload
        expect(csat_survey.name).to eq('Updated CSAT Survey Name')
        expect(csat_survey.prompt).to eq('How was your experience today?')
      end
    end
  end

  describe 'DELETE /csat_surveys/:id' do
    it 'destroys the CSAT survey' do
      survey_id = csat_survey.id
      expect {
        delete csat_survey_path(id: survey_id, locale: :en)
      }.to change { account.with_shard { Csat::Survey.where(account_id: account.id).count } }.by(-1)

      expect(response).to redirect_to(csat_surveys_path)
      expect(account.with_shard { Csat::Survey.where(id: survey_id) }).not_to exist
    end
  end
end
