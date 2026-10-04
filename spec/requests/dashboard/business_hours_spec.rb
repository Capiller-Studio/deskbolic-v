# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::BusinessHourGroups', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'business_hours' => true, 'roles' => true },
      limits: { 'business_hour_groups' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:business_hour_group) do
    account.with_shard do
      create(:business_hour_group, account: account, name: 'Support Americas', timezone: 'Eastern Time (US & Canada)')
    end
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /business_hours' do
    it 'renders the business hours index' do
      business_hour_group
      get business_hour_groups_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Support Americas')
    end

    it 'supports i18n locales' do
      get business_hour_groups_path(locale: :es)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /business_hours/new' do
    it 'renders the new business hour group form' do
      get new_business_hour_group_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('business_hour_group[name]')
      expect(response.body).to include('business_hour_group[timezone]')
    end
  end

  describe 'POST /business_hours' do
    it 'creates a business hour group with weekly schedules' do
      expect {
        post business_hour_groups_path(locale: :en), params: {
          business_hour_group: {
            name: 'APAC Shift Hours',
            description: 'Tokyo and Singapore office hours',
            timezone: 'Tokyo',
            business_hours_attributes: [
              { day_of_week: 'monday', opening_time: '09:00', closing_time: '18:00' },
              { day_of_week: 'tuesday', opening_time: '09:00', closing_time: '18:00' }
            ]
          }
        }
      }.to change { account.with_shard { BusinessHourGroup.where(account_id: account.id).count } }.by(1)

      expect(response).to redirect_to(business_hour_groups_path)
      created = account.with_shard { BusinessHourGroup.where(account_id: account.id).find_by(name: 'APAC Shift Hours') }
      expect(created).to be_present
      expect(created.timezone).to eq('Tokyo')
    end

    it 'renders new with unprocessable entity on validation failure' do
      post business_hour_groups_path(locale: :en), params: {
        business_hour_group: { name: '' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /business_hours/:id/edit' do
    it 'renders edit form' do
      get edit_business_hour_group_path(id: business_hour_group.id, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Support Americas')
    end
  end

  describe 'PATCH /business_hours/:id' do
    it 'updates group name and timezone' do
      patch business_hour_group_path(id: business_hour_group.id, locale: :en), params: {
        business_hour_group: {
          name: 'Support Americas (Updated)',
          timezone: 'Central Time (US & Canada)'
        }
      }
      expect(response).to redirect_to(business_hour_groups_path)
      account.with_shard do
        business_hour_group.reload
        expect(business_hour_group.name).to eq('Support Americas (Updated)')
        expect(business_hour_group.timezone).to eq('Central Time (US & Canada)')
      end
    end
  end

  describe 'DELETE /business_hours/:id' do
    it 'destroys the business hour group' do
      group_id = business_hour_group.id
      expect {
        delete business_hour_group_path(id: group_id, locale: :en)
      }.to change { account.with_shard { BusinessHourGroup.where(account_id: account.id).count } }.by(-1)

      expect(response).to redirect_to(business_hour_groups_path)
      expect(account.with_shard { BusinessHourGroup.where(id: group_id) }).not_to exist
    end
  end
end
