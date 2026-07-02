# frozen_string_literal: true

module Dashboard
  class NotificationSubscriptionPolicy < ApplicationPolicy
    def create?
      record.user_id == user.id
    end

    def destroy?
      record.user_id == user.id
    end
  end
end
