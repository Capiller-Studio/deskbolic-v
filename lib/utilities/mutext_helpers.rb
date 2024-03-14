# frozen_string_literal: true

module RedisUtilities
  class MutexHelpers
    TIMEOUT = 10.seconds

    def self.with_lock(key, timeout: TIMEOUT)
      if lock(key, timeout:)
        yield
        unlock(key)
      else
        false
        # TODO: Error handling and raise exception
      end
    rescue StandardError => _e
      # TODO: Error handling
    end

    def self.lock(key, timeout: TIMEOUT)
      value = Time.now.to_f.to_s

      RedisUtilities::Helpers.set(key, value, overwrite: false, expiry: timeout)
    end

    def self.unlock(key)
      RedisUtilities::Helpers.delete(key)
      true
    end

    def self.locked?(key)
      RedisUtilities::Helpers.exists?(key)
    end
  end
end
