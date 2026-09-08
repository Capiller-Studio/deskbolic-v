# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Settings::NotificationSettings Routes and Updates', type: :request do
  let(:account) { create(:account) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:user) { create(:user, password: 'password123', confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /settings/notifications/edit' do
    it 'renders notification settings page' do
      get edit_settings_notifications_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT /settings/notifications' do
    it 'updates notification settings and redirects to edit_settings_notifications_path' do
      put settings_notifications_path(locale: :en), params: {
        notification_setting: {
          email_conversation_created: true
        }
      }

      expect(response).to redirect_to(edit_settings_notifications_path)
    end
  end
end
