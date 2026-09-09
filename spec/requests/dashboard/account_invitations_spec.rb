# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::AccountInvitations', type: :request do
  let(:account) { create(:account, name: 'Acme Corp', identifier: 'acme-corp') }
  let(:inviter) { create(:user, confirmed_at: Time.current) }
  let!(:inviter_account_user) { create(:account_user, account: account, user: inviter, owner: true) }
  let(:role) do
    account.with_shard do
      create(:access_role, account: account, name: 'Support Agent')
    end
  end
  let(:invitation) do
    create(
      :account_invitation,
      account: account,
      invited_by: inviter,
      email: 'newbie@example.com',
      role_ids: [ role.id ]
    )
  end

  describe 'GET /invite/:token' do
    context 'when user is not authenticated' do
      it 'renders the invitation page successfully without redirecting to login' do
        get invite_path(token: invitation.token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Acme Corp')
        expect(response.body).to include('newbie@example.com')
        expect(response.body).to include('name="user[password]"')
      end
    end

    context 'when user is already signed in with matching email' do
      let(:existing_user) { create(:user, email: 'newbie@example.com', confirmed_at: Time.current) }

      before { sign_in existing_user }

      it 'renders the invitation page with 1-click join button and no password fields' do
        get invite_path(token: invitation.token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Acme Corp')
        expect(response.body).to include('type="submit"')
        expect(response.body).not_to include('name="user[password]"')
      end
    end

    context 'when invitation token does not exist' do
      it 'redirects to login with an invalid or expired alert' do
        get invite_path(token: 'non-existent-token')

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('accounts.invitations.errors.expired'))
      end
    end

    context 'when invitation has expired' do
      before do
        invitation.update_columns(expires_at: 1.day.ago)
      end

      it 'redirects to login with an invalid or expired alert' do
        get invite_path(token: invitation.token)

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('accounts.invitations.errors.expired'))
      end
    end

    context 'when invitation has already been accepted' do
      before do
        invitation.update_columns(status: AccountInvitation.statuses[:accepted])
      end

      it 'redirects to login with an already accepted alert' do
        get invite_path(token: invitation.token)

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('accounts.invitations.errors.already_accepted'))
      end
    end

    context 'when invitation is revoked' do
      before do
        invitation.update_columns(status: AccountInvitation.statuses[:revoked])
      end

      it 'redirects to login with an expired alert' do
        get invite_path(token: invitation.token)

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq(I18n.t('accounts.invitations.errors.expired'))
      end
    end
  end

  describe 'POST /invite/:token' do
    context 'when accepting as a new user' do
      let(:valid_params) do
        {
          token: invitation.token,
          user: {
            first_name: 'Jane',
            last_name: 'Doe',
            password: 'Password123!'
          },
          confirm_password: 'Password123!'
        }
      end

      it 'creates the user, accepts invitation, assigns roles, and redirects to workspace' do
        expect do
          post accept_invite_path(token: invitation.token), params: valid_params
        end.to change(User, :count).by(1)

        new_user = User.find_by(email: 'newbie@example.com')
        expect(new_user).to be_present
        expect(new_user.first_name).to eq('Jane')
        expect(new_user.last_name).to eq('Doe')

        expect(invitation.reload).to be_accepted
        expect(account.users).to include(new_user)

        # Check role assignment in shard
        account.with_shard do
          account_user = account.account_users.find_by(user: new_user)
          expect(Access::AccountUserRole.where(account_user_id: account_user.id, role_id: role.id)).to exist
        end

        expect(response).to redirect_to(root_url(subdomain: account.identifier))
      end

      it 'fails with 422 if password and confirmation do not match' do
        post accept_invite_path(token: invitation.token), params: {
          token: invitation.token,
          user: {
            first_name: 'Jane',
            last_name: 'Doe',
            password: 'Password123!'
          },
          confirm_password: 'MismatchPassword!'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include('Passwords do not match')
        expect(invitation.reload).to be_pending
      end
    end

    context 'when accepting as an existing user' do
      let!(:existing_user) do
        create(:user, email: 'newbie@example.com', first_name: 'Existing', last_name: 'User', confirmed_at: Time.current)
      end

      it 'accepts invitation and joins account without re-prompting for password' do
        expect do
          post accept_invite_path(token: invitation.token), params: { token: invitation.token }
        end.not_to change(User, :count)

        expect(invitation.reload).to be_accepted
        expect(account.users).to include(existing_user)

        account.with_shard do
          account_user = account.account_users.find_by(user: existing_user)
          expect(Access::AccountUserRole.where(account_user_id: account_user.id, role_id: role.id)).to exist
        end

        expect(response).to redirect_to(root_url(subdomain: account.identifier))
      end

      context 'when logged in as a different user' do
        let(:other_user) { create(:user, email: 'other@example.com', confirmed_at: Time.current) }

        before { sign_in other_user }

        it 'switches session to the invited user and redirects to workspace' do
          post accept_invite_path(token: invitation.token), params: { token: invitation.token }

          expect(response).to redirect_to(root_url(subdomain: account.identifier))
          expect(controller.current_user).to eq(existing_user)
        end
      end
    end
  end
end
