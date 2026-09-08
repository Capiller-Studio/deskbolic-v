# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Profile Deletion', type: :request do
  let(:account) { create(:account) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
  end

  describe 'GET /profile' do
    let(:user) { create(:user, confirmed_at: Time.current) }
    let!(:account_user) { create(:account_user, account: account, user: user, owner: false) }

    before { sign_in user }

    it 'renders profile page with professional deletion warning and permanent loss disclosure in English' do
      get profile_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Staff members will review and do manual verifications, then permanently delete your data')
      expect(response.body).to include('active devices, active sessions, and notification subscriptions')
    end

    it 'renders profile page with professional deletion warning and permanent loss disclosure in Spanish' do
      get profile_path(locale: :es)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Eliminar cuenta personal')
      expect(response.body).to include('Los miembros del equipo revisarán y realizarán verificaciones manuales, y luego eliminarán permanentemente sus datos')
      expect(response.body).to include('los dispositivos activos, las sesiones activas y las suscripciones a notificaciones')
    end
  end

  describe 'DELETE /profile' do
    context 'when user is the owner of an active workspace' do
      let(:owner_user) { create(:user, password: 'password123', confirmed_at: Time.current) }
      let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

      before { sign_in owner_user }

      it 'prevents account deletion and alerts the owner' do
        delete profile_path(locale: :en), params: { password: 'password123' }

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include('You are the owner of an active workspace')
        expect(owner_user.reload).to be_active
      end
    end

    context 'when user is not an owner of any active workspace' do
      let(:agent_user) { create(:user, password: 'password123', confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      before { sign_in agent_user }

      it 'rejects deletion when password is wrong' do
        delete profile_path(locale: :en), params: { password: 'wrongpassword' }

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include('Incorrect password')
        expect(agent_user.reload).to be_active
      end

      it 'successfully deactivates user profile, records activity, and signs out' do
        delete profile_path(locale: :en), params: { password: 'password123' }

        expect(response).to redirect_to(new_user_session_path)
        expect(agent_user.reload).to be_pending_deletion
        expect(agent_user.active_for_authentication?).to be false
      end
    end
  end
end
