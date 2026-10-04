# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Notifications', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /notifications' do
    it 'renders notification panel list' do
      create(:notification, user: user, resource: conversation, event: 'conversation_created')

      get notifications_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('notifications-slide-over')
      expect(response.body).to include('notifications-list')
    end

    it 'renders matching turbo-frame for lazy pagination without Content missing' do
      25.times do
        create(:notification, user: user, resource: conversation, event: 'conversation_created')
      end

      get notifications_path(page: 2, locale: :en), headers: { 'Turbo-Frame' => 'notifications-page-2' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="notifications-page-2"')
      expect(response.body).not_to include('Content missing')
    end
  end

  describe 'POST /notifications/:id/mark_read' do
    it 'marks notification as read' do
      notification = create(:notification, user: user, resource: conversation, event: 'conversation_created')

      post mark_read_notification_path(id: notification.id, locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(notification.reload.read_at).to be_present
    end
  end

  describe 'POST /notifications/mark_all_read' do
    it 'marks all notifications as read' do
      create_list(:notification, 3, user: user, resource: conversation, event: 'conversation_created')

      post mark_all_read_notifications_path(locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(user.notifications.unread.count).to eq(0)
    end
  end
end
