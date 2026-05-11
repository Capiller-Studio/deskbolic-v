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
      can?("macros.manage")
    end

    def update?
      return false if record.is_system? && !owner?
      return false if record.personal? && !record.owned_by?(user) && !owner?

      can?("macros.manage")
    end

    def destroy?
      return false if record.is_system?
      return false if record.personal? && !record.owned_by?(user) && !owner?

      can?("macros.manage")
    end

    def execute?
      can?("macros.execute")
    end
  end
end
