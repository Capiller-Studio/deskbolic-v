# frozen_string_literal: true

module Dashboard
  class BusinessHourGroupPolicy < ApplicationPolicy
    def index?
      authorized?("business_hours.read", feature: :business_hours)
    end

    def show?
      index?
    end

    def create?
      authorized?("business_hours.manage", feature: :business_hours, limit: :business_hour_groups)
    end

    def update?
      authorized?("business_hours.manage", feature: :business_hours)
    end

    def destroy?
      authorized?("business_hours.manage", feature: :business_hours)
    end
  end
end
