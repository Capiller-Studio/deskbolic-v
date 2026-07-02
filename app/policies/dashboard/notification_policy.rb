# frozen_string_literal: true

module Dashboard
  class NotificationPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def update_badge?
      index?
    end

    def mark_all_read?
      user.present?
    end

    def mark_read?
      record.user_id == user.id
    end

    class Scope < Scope
      def resolve
        scope.where(user: user)
      end
    end
  end
end
