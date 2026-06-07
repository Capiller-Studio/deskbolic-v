# frozen_string_literal: true

module Dashboard
  class SkillPolicy < ApplicationPolicy
    def index?
      authorized?("skills.read", feature: :assignment_policies_enabled)
    end

    def create?
      authorized?("skills.manage", feature: :assignment_policies_enabled)
    end

    def update?
      authorized?("skills.manage", feature: :assignment_policies_enabled)
    end

    def destroy?
      authorized?("skills.manage", feature: :assignment_policies_enabled)
    end
  end
end
