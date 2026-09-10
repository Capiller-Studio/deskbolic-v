# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Team Member Invitation Acceptance Feature', type: :feature do
  let(:account) { create(:account, name: 'Stark Logistics', identifier: 'stark-logistics') }
  let(:inviter) { create(:user, confirmed_at: Time.current) }
  let!(:inviter_account_user) { create(:account_user, account: account, user: inviter, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
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
      email: 'recruit@example.com',
      role_ids: [ role.id ]
    )
  end

  context 'when accepting as an existing signed-in user' do
    let(:member_user) { create(:user, email: 'recruit@example.com', confirmed_at: Time.current) }

    before do
      login_as(member_user, scope: :user)
    end

    it 'allows user to join workspace with 1-click submit' do
      visit invite_path(token: invitation.token)

      expect(page).to have_content('Stark Logistics')
      click_button I18n.t('auth.workspace.email_invitation.join_button')

      expect(invitation.reload).to be_accepted
      expect(account.users).to include(member_user)
    end
  end

  context 'when accepting as a new user' do
    it 'allows the new user to complete sign up and join workspace' do
      visit invite_path(token: invitation.token)

      expect(page).to have_content('Stark Logistics')

      # Fill in user registration fields (second fieldset shown via JS in browser)
      fill_in 'user[first_name]', with: 'Peter', visible: :all
      fill_in 'user[last_name]', with: 'Parker', visible: :all
      fill_in 'user[password]', with: 'P@ssw0rd123!', visible: :all
      fill_in 'confirm_password', with: 'P@ssw0rd123!', visible: :all

      find('input[type="submit"]', visible: :all).click

      expect(invitation.reload).to be_accepted
      new_user = User.find_by(email: 'recruit@example.com')
      expect(new_user).to be_present
      expect(new_user.first_name).to eq('Peter')
      expect(account.users).to include(new_user)
    end
  end

  context 'when invitation token is invalid or expired' do
    it 'redirects to login with an error message' do
      visit invite_path(token: 'invalid-nonexistent-token')

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content(I18n.t('accounts.invitations.errors.expired'))
    end
  end
end
