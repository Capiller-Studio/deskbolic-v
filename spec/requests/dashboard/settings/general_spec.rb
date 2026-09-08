# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Settings::General Workspace Lifecycle', type: :request do
  let(:account) { create(:account) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:owner_user) { create(:user, password: 'password123', confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  before do
    set_subdomain(account.identifier)
    sign_in owner_user
  end

  describe 'GET /settings/general' do
    it 'renders general workspace settings page in English' do
      get settings_general_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.identifier)
      expect(response.body).to include('Staff members will review and do manual verifications, then permanently delete channels')
      expect(response.body).to include('active devices, sessions, and API tokens are permanently lost')
    end

    it 'renders general workspace settings page in Spanish' do
      get settings_general_path(locale: :es)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Eliminar espacio de trabajo')
      expect(response.body).to include('Los miembros del equipo revisarán y realizarán verificaciones manuales')
      expect(response.body).to include('los dispositivos activos, las sesiones y los tokens de API se perderán permanentemente')
    end
  end

  describe 'DELETE /settings/general' do
    context 'when owner confirms with matching slug and password' do
      it 'deactivates workspace and sets status to pending_deletion' do
        delete settings_general_path(locale: :en), params: {
          password: 'password123',
          identifier_confirmation: account.identifier
        }

        expect(response).to redirect_to(new_user_session_path)
        expect(account.reload).to be_pending_deletion
      end
    end

    context 'when confirmation slug does not match' do
      it 'cancels deletion with an alert' do
        delete settings_general_path(locale: :en), params: {
          password: 'password123',
          identifier_confirmation: 'wrong-slug'
        }

        expect(response).to redirect_to(settings_general_path)
        expect(flash[:alert]).to include('does not match')
        expect(account.reload).to be_active
      end
    end

    context 'when password is wrong' do
      it 'cancels deletion with an alert' do
        delete settings_general_path(locale: :en), params: {
          password: 'wrongpassword',
          identifier_confirmation: account.identifier
        }

        expect(response).to redirect_to(settings_general_path)
        expect(flash[:alert]).to include('Incorrect password')
        expect(account.reload).to be_active
      end
    end
  end

  describe 'AccountStatusGuarded guard' do
    it 'blocks normal dashboard requests when workspace is pending deletion' do
      account.deactivate_for_deletion!

      get conversations_path(locale: :en)
      expect(response).to redirect_to(workspace_url(subdomain: ""))
      expect(flash[:alert]).to include('deactivated')
    end
  end
end
