# frozen_string_literal: true

module Dashboard
  class SkillPolicy < ApplicationPolicy
    def index?
      authorized?("skills.read", feature: :assignment_policies)
    end

    def create?
      authorized?("skills.manage", feature: :assignment_policies)
    end

    def update?
      authorized?("skills.manage", feature: :assignment_policies)
    end

    def destroy?
      authorized?("skills.manage", feature: :assignment_policies)
    end
  end
end
