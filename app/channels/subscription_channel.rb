# frozen_string_literal: true

class SubscriptionChannel < ApplicationCable::Channel
  attr_accessor :connection_token

  before_subscribe :configure_connection_token
  before_subscribe :current_subscriber

  def subscribed
    current_account.with_shard do
      stream_from(connection_token)
      track_activity
      broadcast_activity
      drain_unassigned_queue if current_user
    end
  end

  def unsubscribed; end

  # def receive(data)
  # end

  def ping
    activity
  end

  def activity
    track_activity
    broadcast_activity
  end

  private

  def configure_connection_token
    reject if params[:connection_token].blank?
    self.connection_token = params[:connection_token]
  end

  def current_subscriber
    @current_subscriber ||= current_user || current_customer
  end

  def current_account
    @current_account ||= if current_user
                           #  current_user.accounts.find!(params[:account_id])
                           current_user.account_users.first.account
    else
                           current_customer.account
    end
  end

  def track_activity
    Utilities::ActivityHelpers.update_activity(
      current_account.id,
      current_subscriber.class.name,
      current_subscriber.id
    )
  end

  def broadcast_activity
    _users     = Utilities::ActivityHelpers.available_users(current_account.id)
    _customers = Utilities::ActivityHelpers.available_customers(current_account.id)

    ActionCable.server.broadcast(
      connection_token,
      {
        event: "presence.update",
        data: {
          users: _users,
          customers: _customers
        }
      }
    )
  end

  def drain_unassigned_queue
    return unless AssignmentPolicies::BacklogTracker.backlog_pending?(current_account.id)

    throttle_key = "QUEUE_DRAIN_THROTTLE:#{current_account.id}"
    # Throttle: enqueue at most once every 60 seconds per account on agent connections
    acquired = RedisUtilities::Helpers.set(throttle_key, "1", overwrite: false, expiry: 60)
    return unless acquired

    AssignmentPolicies::QueueDrainWorker.perform_async(current_account.id)
  rescue StandardError => e
    Rails.logger.warn("Failed to enqueue QueueDrainWorker: #{e.message}")
  end
end
