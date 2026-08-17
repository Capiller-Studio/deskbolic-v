# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionChannel, type: :channel do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user) }

  before do
    stub_connection current_user: user
    allow(Utilities::ActivityHelpers).to receive(:update_activity)
    allow(Utilities::ActivityHelpers).to receive_messages(available_users: [], available_customers: [])
  end

  it 'subscribes and streams from connection token' do
    subscribe connection_token: 'test_token_123'
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('test_token_123')
  end

  it 'rejects subscription without connection token' do
    subscribe
    expect(subscription).to be_rejected
  end

  it 'handles ping and activity' do
    subscribe connection_token: 'test_token_123'
    perform :ping
    expect(Utilities::ActivityHelpers).to have_received(:update_activity).at_least(:once)
  end
end
