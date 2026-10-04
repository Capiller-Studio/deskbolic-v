# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Settings::AuditLogs', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, features: { 'audit_logs' => true }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /settings/audit_logs' do
    let!(:activity) do
      account.with_shard do
        create(
          :activity,
          account: account,
          actor: user,
          event_key: 'channel/whatsapp.update',
          object_changes: {
            'api_key' => [ 'EAABwz_old_secret_123', 'EAABwz_new_secret_456' ],
            'name' => [ 'Old Support', 'New Support' ]
          },
          object_snapshot: { 'name' => 'New Support', 'api_key' => 'EAABwz_new_secret_456' }
        )
      end
    end

    it 'renders the audit logs page successfully with sensitive data masked' do
      get settings_audit_logs_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Audit Logs')
      expect(response.body).to include('New Support')
      # Verifies that sensitive data is masked in the UI with bullet points and not in cleartext
      expect(response.body).to include('••••••••')
      expect(response.body).not_to include('EAABwz_old_secret_123')
      expect(response.body).not_to include('EAABwz_new_secret_456')
    end

    it 'filters audit logs by actor' do
      get settings_audit_logs_path(locale: :en, actor_id: user.id)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /settings/audit_logs/:id/revert' do
    let(:label) do
      account.with_shard do
        Label.create!(account: account, title: 'Original Title', color: '#112233')
      end
    end

    let!(:activity) do
      account.with_shard do
        label.update!(title: 'Changed Title')
        create(
          :activity,
          account: account,
          actor: user,
          trackable: label,
          event_key: 'label.update',
          object_changes: { 'title' => [ 'Original Title', 'Changed Title' ] },
          object_snapshot: { 'title' => 'Original Title', 'color' => '#112233' }
        )
      end
    end

    it 'reverts the activity via undo' do
      post revert_settings_audit_log_path(id: activity.id, locale: :en, mode: 'undo')
      expect(response).to redirect_to(settings_audit_logs_path)
      follow_redirect!
      expect(response.body).to include('Activity successfully reverted.')

      account.with_shard do
        expect(label.reload.title).to eq('Original Title')
      end
    end
  end
end
