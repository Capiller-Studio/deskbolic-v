# frozen_string_literal: true

module Dashboard
  class AssignmentPolicyPolicy < ApplicationPolicy
    def index?
      authorized?("assignment_policies.read", feature: :assignment_policies_enabled)
    end

    def show?
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

    def toggle?
      update?
    end

    def reorder?
      authorized?("assignment_policies.manage", feature: :assignment_policies_enabled)
    end
  end
end
