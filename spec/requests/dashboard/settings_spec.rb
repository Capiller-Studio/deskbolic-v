# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Settings', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /settings' do
    it 'renders settings index' do
      get settings_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /settings/channels' do
    it 'renders channels overview page' do
      get channels_settings_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /settings/canned_responses' do
    it 'renders canned responses settings' do
      get canned_responses_settings_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /settings/inboxes' do
    it 'renders inboxes settings page' do
      get inboxes_settings_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Inboxes')
    end
  end
end
