# frozen_string_literal: true

module Dashboard
  class ScimTokenPolicy < ApplicationPolicy
    def index?
      authorized?("sso.read", feature: :sso)
    end

    def create?
      authorized?("sso.manage", feature: :sso)
    end

    def destroy?
      authorized?("sso.manage", feature: :sso)
    end
  end
end
