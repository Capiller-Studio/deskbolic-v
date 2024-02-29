# frozen_string_literal: true

class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    de: { writing: :primary_de, reading: :primary_de_replica }
  }
end
