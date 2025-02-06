# frozen_string_literal: true

module Reauthorizable
  extend ActiveSupport::Concern

  AUTHORIZATION_ERROR_THRESHOLD = 3

  def reauthorization_required?
    RedisUtilities::Helpers.get(reauthorization_required_key).present?
  end

  def authorization_error_count
    RedisUtilities::Helpers.get(authorization_error_count_key).to_i
  end

  # Call after receiving an authorization error
  def authorization_error!
    RedisUtilities::Helpers.increment(authorization_error_count_key)
    authorization_error_alert! if authorization_error_count >= self.class::AUTHORIZATION_ERROR_THRESHOLD
  end

  def authorization_error_alert!
    RedisUtilities::Helpers.set(reauthorization_required_key, true)

    ## Send notification to user and show dialog in the frontend.
    self.class.name

    invalidate_cache
  end

  # Call after fixing authorization error
  def reauthorized!
    RedisUtilities::Helpers.delete(authorization_error_count_key)
    RedisUtilities::Helpers.delete(reauthorization_required_key)

    invalidate_cache
  end

  private

  def invalidate_cache
    ## TODO: Work in progress. Add redis based cache at account level
  end

  def authorization_error_count_key
    @authorization_error_count_key ||=
      format(RedisUtilities::Keys::AUTHORIZATION_ERROR_COUNT, resource_name: self.class.table_name.singularize,
resource_id: id)
  end

  def reauthorization_required_key
    @reauthorization_required_key ||=
      format(RedisUtilities::Keys::REAUTHORIZATION_REQUIRED, resource_name: self.class.table_name.singularize,
resource_id: id)
  end
end
