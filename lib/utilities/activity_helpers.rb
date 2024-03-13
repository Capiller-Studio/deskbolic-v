# frozen_string_literal: true

module Utilities
  module ActivityHelpers
    ACTIVITY_MARGIN = 30.seconds

    def self.update_activity(account_id, resource_type, resource_id)
      RedisUtilities::Helpers.add_with_score(
        activity_key(account_id, resource_type),
        Time.now.to_i,
        resource_id
      )
    end

    def self.activity?(account_id, resource_type, resource_id)
      time = RedisUtilities::Helpers.get_score(activity_key(account_id, resource_type), resource_id)
      time && time > (Time.zone.now - ACTIVITY_MARGIN).to_i
    end

    def self.activity_key(account_id, type)
      format(
        "RedisUtilities::Keys::#{type.pluralize.upcase}_ACTIVITY".constantize,
        account_id:
      )
    end

    def self.availability_key(account_id)
      format(RedisUtilities::Keys::ONLINE_STATUS, account_id:)
    end

    def self.availability=(account_id, user_id, status)
      RedisUtilities::Helpers.hash_set(
        availability_key(account_id),
        user_id,
        status.to_s.downcase
      )
    end

    def self.availability(account_id, user_id)
      RedisUtilities::Helpers.hash_get(availability_key(account_id), user_id)
    end

    def self.available_customer_ids(account_id)
      from = (Time.zone.now - ACTIVITY_MARGIN).to_i

      RedisUtilities::Helpers.remove_elements_by_score(activity_key(account_id, "Customer"), "-inf", "(#{from}")
      RedisUtilities::Helpers.sorted_subset(activity_key(account_id, "Customer"), from, "+inf")
    end

    def self.available_customers(account_id)
      available_customer_ids(account_id).index_with { |_id| "online" }
    end

    def self.available_users(account_id)
      user_ids = available_user_ids(account_id)

      return {} if user_ids.blank?

      user_availabilities = RedisUtilities::Helpers.hash_multi_get(availability_key(account_id), user_ids)
      user_ids.map.with_index { |id, index| [id, (user_availabilities[index] || "online")] }.to_h
    end

    def self.available_user_ids(account_id)
      from = (Time.zone.now - ACTIVITY_MARGIN).to_i
      RedisUtilities::Helpers.sorted_subset(activity_key(account_id, "User"), from, "+inf")
    end
  end
end
