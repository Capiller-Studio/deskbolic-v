# frozen_string_literal: true

module Dashboard
  class AutomationPolicy < ApplicationPolicy
    def index?
      authorized?("automations.read", feature: :automations_enabled)
    end

    def show?
      authorized?("automations.read", feature: :automations_enabled)
    end

    def create?
      authorized?("automations.manage", feature: :automations_enabled, limit: :automations)
    end

    def update?
      return false if record.is_system? && !owner?

      authorized?("automations.manage", feature: :automations_enabled)
    end

    def destroy?
      return false if record.is_system?

      authorized?("automations.manage", feature: :automations_enabled)
    end

    def toggle?
      update?
    end

    def duplicate?
      create?
    end

    def reorder?
      authorized?("automations.manage", feature: :automations_enabled)
    end

    def lookups?
      authorized?("automations.read", feature: :automations_enabled)
    end
  end
end
