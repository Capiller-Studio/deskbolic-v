# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication Feature', type: :feature do
  let(:password) { 'ValidP@ssw0rd123!' }
  let(:user) { create(:user, password: password, password_confirmation: password, confirmed_at: Time.current) }

  context 'when user has no workspaces' do
    it 'allows user to sign in and redirects to workspace creation' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: password
      click_button 'Sign in'

      expect(current_path).to eq(workspace_path)
    end
  end

  context 'when user has multiple workspaces' do
    let!(:account1) { create(:account, status: :active) }
    let!(:account2) { create(:account, status: :active) }
    let!(:account_user1) { create(:account_user, account: account1, user: user, owner: true) }
    let!(:account_user2) { create(:account_user, account: account2, user: user) }

    it 'redirects to workspace chooser on apex domain' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: password
      click_button 'Sign in'

      expect(current_path).to eq(workspaces_path)
      expect(page).to have_content(account1.name)
      expect(page).to have_content(account2.name)
    end
  end

  context 'with invalid credentials' do
    it 'displays an authentication error' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'WrongPassword'
      click_button 'Sign in'

      expect(page).to have_content('Invalid')
    end
  end

  context 'when signed in' do
    let(:account) { create(:account, status: :active) }
    let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

    it 'allows user to sign out' do
      login_as(user, scope: :user)
      visit workspaces_path

      click_link 'Sign Out'
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
