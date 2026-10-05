# frozen_string_literal: true

module Dashboard
  class MacroPolicy < ApplicationPolicy
    def index?
      can?("macros.read")
    end

    def show?
      can?("macros.read")
    end

    def available?
      can?("macros.execute") || can?("macros.read")
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

    def toggle?
      update?
    end

    def execute?
      return false unless can?("macros.execute")
      return false if record.is_a?(Macro) && (!record.active? || !record.visible_to?(user))

      true
    end
  end
end
