# frozen_string_literal: true

module Dashboard
  class IntegrationPolicy < ApplicationPolicy
    def index?
      authorized?("integrations.read")
    end

    def create?
      authorized?("integrations.manage")
    end

    def update?
      authorized?("integrations.manage")
    end

    def destroy?
      authorized?("integrations.manage")
    end

    def slack_callback?
      authorized?("integrations.manage")
    end
  end
end
