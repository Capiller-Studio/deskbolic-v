# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workspaces Feature', type: :feature do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account1) { create(:account, name: 'Acme Corp', status: :active) }
  let!(:account2) { create(:account, name: 'Stark Industries', status: :active) }
  let!(:account_user1) { create(:account_user, account: account1, user: user, owner: true) }
  let!(:account_user2) { create(:account_user, account: account2, user: user, owner: false) }

  before do
    login_as(user, scope: :user)
  end

  describe 'listing workspaces' do
    it 'displays all workspaces with proper roles' do
      visit workspaces_path

      expect(page).to have_content('Acme Corp')
      expect(page).to have_content('Stark Industries')
      expect(page).to have_content('Owner')
      expect(page).to have_content('Member')
    end
  end

  describe 'creating a workspace' do
    it 'creates a new workspace successfully' do
      visit workspaces_path
      click_link I18n.t('dashboard.workspace.chooser.create_new')

      expect(current_path).to eq(workspace_path)

      fill_in 'account[name]', with: 'Wayne Enterprises'
      choose 'shard_key_de'
      click_button I18n.t('dashboard.workspace.new.create_workspace_button')

      new_account = Account.find_by(name: 'Wayne Enterprises')
      expect(new_account).to be_present
      expect(new_account.account_users.find_by(user: user)).to be_owner
    end

    it 'shows an alert when workspace creation fails' do
      visit workspace_path

      fill_in 'account[name]', with: ''
      click_button I18n.t('dashboard.workspace.new.create_workspace_button')

      expect(page).to have_content("can't be blank")
    end
  end
end
