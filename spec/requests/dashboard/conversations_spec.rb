# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Conversations', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /conversations' do
    it 'renders conversations index' do
      get conversations_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /conversations/:id' do
    it 'renders conversation show' do
      get conversation_path(id: conversation.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /conversations/:id' do
    it 'updates conversation status' do
      patch conversation_path(id: conversation.id, locale: :en), params: { conversation: { status: 'resolved' } }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.reload.status).to eq('resolved')
    end

    it 'updates conversation priority' do
      patch conversation_path(id: conversation.id, locale: :en), params: { conversation: { priority: 'urgent' } }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.reload.priority).to eq('urgent')
    end
  end
end
