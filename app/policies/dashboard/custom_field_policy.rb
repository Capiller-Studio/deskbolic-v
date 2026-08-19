# frozen_string_literal: true

module Dashboard
  class CustomFieldPolicy < ApplicationPolicy
    def index?
      authorized?("custom_fields.read", feature: "custom_fields")
    end

    def create?
      authorized?("custom_fields.manage", feature: "custom_fields", limit: :custom_fields)
    end

    def show?
      index?
    end

    def new?
      create?
    end

    def edit?
      create?
    end

    def update?
      create?
    end

    def destroy?
      create?
    end
  end
end
