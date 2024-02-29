# frozen_string_literal: true

class Note < ShardRecord
  belongs_to :resource, polymorphic: true
  belongs_to :user
  belongs_to :account

  enum visibility: { personal: 0, global: 1 }
end
