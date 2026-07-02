# frozen_string_literal: true

module Dashboard
  class ActivityPolicy < ApplicationPolicy
    def append_activity?
      record.account_id == account.id
    end
  end
end
