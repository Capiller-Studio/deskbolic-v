# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Messages', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'POST /messages' do
    it 'creates an outgoing agent message' do
      post messages_path(locale: :en),
           params: {
             message: {
               conversation_id: conversation.id,
               response: 'Hello! How can I help you today?',
               message_type: 'outgoing'
             }
           },
           headers: { 'HTTP_REFERER' => "/en/conversations/#{conversation.id}" }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.messages.where(content: 'Hello! How can I help you today?')).to exist
    end
  end
end
