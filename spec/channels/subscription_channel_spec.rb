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

  it 'enqueues QueueDrainWorker when agent subscribes if not throttled' do
    allow(RedisUtilities::Helpers).to receive(:set).with("QUEUE_DRAIN_THROTTLE:#{account.id}", '1', overwrite: false, expiry: 60).and_return(true)
    expect(AssignmentPolicies::QueueDrainWorker).to receive(:perform_async).with(account.id)
    subscribe connection_token: 'test_token_123'
  end

  it 'throttles QueueDrainWorker enqueue on subsequent subscriptions within window' do
    allow(RedisUtilities::Helpers).to receive(:set).with("QUEUE_DRAIN_THROTTLE:#{account.id}", '1', overwrite: false, expiry: 60).and_return(false)
    expect(AssignmentPolicies::QueueDrainWorker).not_to receive(:perform_async)
    subscribe connection_token: 'test_token_123'
  end

  it 'skips QueueDrainWorker completely if backlog is confirmed empty' do
    allow(AssignmentPolicies::BacklogTracker).to receive(:backlog_pending?).with(account.id).and_return(false)
    expect(AssignmentPolicies::QueueDrainWorker).not_to receive(:perform_async)
    subscribe connection_token: 'test_token_123'
  end
end
