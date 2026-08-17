# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Unlocks', type: :request do
  describe 'GET /users/unlock/new' do
    it 'renders resend unlock page' do
      get new_user_unlock_path
      expect(response).to have_http_status(:ok)
    end
  end
end
