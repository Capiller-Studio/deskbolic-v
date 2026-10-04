# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password Reset Feature', type: :feature do
  let(:old_password) { 'OldP@ssw0rd123!' }
  let(:new_password) { 'NewP@ssw0rd456!' }
  let(:user) { create(:user, password: old_password, password_confirmation: old_password, confirmed_at: Time.current) }
  let(:raw_token) do
    raw, enc = Devise.token_generator.generate(User, :reset_password_token)
    user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)
    raw
  end

  it 'allows resetting password via reset password link when not signed in' do
    visit edit_user_password_path(reset_password_token: raw_token)

    expect(page).to have_text(I18n.t('auth.passwords.reset_title'))
    fill_in 'user[password]', with: new_password
    fill_in 'user[password_confirmation]', with: new_password
    click_button I18n.t('auth.passwords.change_my_password')

    expect(user.reload.valid_password?(new_password)).to be(true)
  end

  it 'allows resetting password via reset password link even if currently signed in' do
    login_as(user, scope: :user)

    visit edit_user_password_path(reset_password_token: raw_token)

    expect(page).to have_text(I18n.t('auth.passwords.reset_title'))
    fill_in 'user[password]', with: new_password
    fill_in 'user[password_confirmation]', with: new_password
    click_button I18n.t('auth.passwords.change_my_password')

    expect(user.reload.valid_password?(new_password)).to be(true)
  end
end
