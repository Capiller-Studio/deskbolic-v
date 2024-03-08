# frozen_string_literal: true

module Redis
  module Helpers
    include Redis::Keys

    CONNECTION_POOL = ConnectionPool.new(size: 10, timeout: 1) do
      Redis.new
    end

    def self.set(key, value, overwrite: true, expiry: false)
      CONNECTION_POOL.with { |redis| redis.set(key, value, nx: !overwrite, ex: expiry) }
    end

    def self.get(key)
      CONNECTION_POOL.with { |redis| redis.get(key) }
    end

    def self.delete(key)
      CONNECTION_POOL.with { |redis| redis.del(key) }
    end

    def self.exists?(key)
      CONNECTION_POOL.with { |redis| redis.exists?(key) }
    end

    def self.increment(key)
      CONNECTION_POOL.with { |redis| redis.incr(key) }
    end

    def self.size(key)
      CONNECTION_POOL.with { |redis| redis.llen(key) }
    end

    def self.subset(key, from: 0, to: -1)
      CONNECTION_POOL.with { |redis| redis.lrange(key, from, to) }
    end

    def self.push(key, values)
      CONNECTION_POOL.with { |redis| redis.lpush(key, values) }
    end

    def self.pop(key)
      CONNECTION_POOL.with { |redis| redis.rpop(key) }
    end

    def self.pop_push(source, destination)
      CONNECTION_POOL.with { |redis| redis.rpoplpush(source, destination) }
    end

    def self.remove_element(key, value, count: 0)
      CONNECTION_POOL.with { |redis| redis.lrem(key, count, value) }
    end

    def self.hash_set(key, field, value)
      CONNECTION_POOL.with { |redis| redis.hset(key, field, value) }
    end

    def self.hash_get(key, field)
      CONNECTION_POOL.with { |redis| redis.hget(key, field) }
    end

    def self.hash_multi_get(key, fields)
      CONNECTION_POOL.with { |redis| redis.hmget(key, *fields) }
    end

    def self.add_with_score(key, score, value)
      CONNECTION_POOL.with { |redis| redis.zadd(key, score, value) }
    end

    def self.get_score(key, value)
      CONNECTION_POOL.with { |redis| redis.zscore(key, value) }
    end

    def self.sorted_subset(key, from, to, reverse: false, by_score: true)
      CONNECTION_POOL.with { |redis| redis.zrange(key, from, to, rev: reverse, byscore: by_score) }
    end

    def self.remove_elements_by_score(key, from, to)
      CONNECTION_POOL.with { |redis| redis.zremrangebyscore(key, from, to) }
    end
  end
end
