# frozen_string_literal: true

module Dashboard
  class MacroPolicy < ApplicationPolicy
    def index?
      can?("macros.read")
    end

    def show?
      can?("macros.read")
    end

    def create?
      authorized?("macros.manage", limit: :macros)
    end

    def update?
      return false if record.system_provided? && !owner?
      return false if record.personal? && !record.owned_by?(user) && !owner?

      can?("macros.manage")
    end

    def destroy?
      return false if record.system_provided?
      return false if record.personal? && !record.owned_by?(user) && !owner?

      can?("macros.manage")
    end

    def execute?
      can?("macros.execute")
    end
  end
end
