# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings Feature', type: :feature do
  let(:account) { create(:account, name: 'Original Acme', status: :active) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, features: { 'labels' => true }, limits: { 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    host_for_account(account)
    login_as(user, scope: :user)
  end

  describe 'general workspace settings' do
    it 'displays workspace details and updates workspace name' do
      visit settings_general_path(locale: :en)

      expect(page).to have_content('General Settings')
      expect(page).to have_field('account[name]', with: 'Original Acme')

      fill_in 'account[name]', with: 'Acme Global Corp'
      click_button 'Save Changes'

      expect(account.reload.name).to eq('Acme Global Corp')
    end
  end

  describe 'labels management' do
    it 'allows creating a new label' do
      visit labels_path(locale: :en)
      expect(page).to have_content('Labels')

      click_link I18n.t('dashboard.labels.index.add_label', default: 'Add label')
      expect(page).to have_field('label[title]')

      fill_in 'label[title]', with: 'Urgent Issue'
      fill_in 'label[description]', with: 'High priority customer tickets'
      click_button 'Create Label'

      expect(current_path).to match(%r{/(en/)?labels})
      expect(page).to have_content('Urgent Issue')
    end

    it 'lists existing labels and allows deleting a label' do
      label = account.with_shard { create(:label, account: account, title: 'Temporary Label') }

      visit labels_path(locale: :en)
      expect(page).to have_content('Temporary Label')

      # Delete the label
      within("#label_#{label.id}") do
        find('button.ui-label-delete-button').click
      end

      expect(page).not_to have_content('Temporary Label')
      expect(account.with_shard { Label.where(id: label.id) }).not_to exist
    end
  end
end
