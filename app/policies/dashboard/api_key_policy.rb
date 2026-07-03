# frozen_string_literal: true

module Dashboard
  class ApiKeyPolicy < ApplicationPolicy
    def index?
      authorized?("account.manage", feature: "api_access")
    end

    def create?
      index?
    end

    def destroy?
      index?
    end
  end
end
