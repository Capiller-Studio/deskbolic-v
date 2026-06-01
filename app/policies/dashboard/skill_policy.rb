# frozen_string_literal: true

module Dashboard
  class SkillPolicy < ApplicationPolicy
    def index?
      authorized?("assignment_policies.read", feature: :assignment_policies_enabled)
    end

    def create?
      authorized?("assignment_policies.manage", feature: :assignment_policies_enabled)
    end

    def update?
      authorized?("assignment_policies.manage", feature: :assignment_policies_enabled)
    end

    def destroy?
      authorized?("assignment_policies.manage", feature: :assignment_policies_enabled)
    end
  end
end
