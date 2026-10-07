# frozen_string_literal: true

module Dashboard
  class NotificationSettingPolicy < ApplicationPolicy
    def edit?
      record.user_id == user.id
    end

    def show?
      edit?
    end

    def update?
      record.user_id == user.id
    end
  end
end
