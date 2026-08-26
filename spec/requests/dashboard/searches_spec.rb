# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Searches', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'channels' => { 'email' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /search' do
    it 'renders the search results page' do
      get search_index_path(locale: :en, q: 'hello')
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /search/suggestions' do
    it 'returns suggestions json with conversation and message results' do
      inbox = account.with_shard { create(:inbox, account: account) }
      conversation = account.with_shard { create(:conversation, account: account, inbox: inbox, title: 'Important question') }
      message = account.with_shard { create(:message, conversation: conversation, account: account, sender: user, content: 'Hello there!') }

      allow_any_instance_of(Search::SearchService).to receive(:suggestions).and_return({
        conversations: [conversation],
        messages: [message]
      })

      get suggestions_search_index_path(locale: :en, q: 'Hello')
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['conversations']).to be_an(Array)
      expect(json['conversations'].first['url']).to include(conversation.id)

      expect(json['messages']).to be_an(Array)
      expect(json['messages'].first['url']).to include("message_id=#{message.id}")
      expect(json['messages'].first['url']).to include("#message_#{message.id}")
    end
  end

  describe 'GET /conversations/:id with target message_id' do
    it 'calculates pagination page for target message_id' do
      inbox = account.with_shard { create(:inbox, account: account) }
      conversation = account.with_shard { create(:conversation, account: account, inbox: inbox) }
      message = account.with_shard { create(:message, conversation: conversation, account: account, sender: user, content: 'Target message') }

      get conversation_path(conversation, message_id: message.id, locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end
end
