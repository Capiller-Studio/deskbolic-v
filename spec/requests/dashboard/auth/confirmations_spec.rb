# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Confirmations', type: :request do
  describe 'GET /users/confirmation/new' do
    it 'renders resend confirmation page' do
      get new_user_confirmation_path
      expect(response).to have_http_status(:ok)
    end
  end
end
