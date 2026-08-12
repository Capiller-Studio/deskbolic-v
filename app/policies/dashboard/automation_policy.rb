# frozen_string_literal: true

module Dashboard
  class AutomationPolicy < ApplicationPolicy
    def index?
      authorized?("automations.read", feature: :automations)
    end

    def show?
      authorized?("automations.read", feature: :automations)
    end

    def create?
      authorized?("automations.manage", feature: :automations, limit: :automations)
    end

    def update?
      return false if record.is_system? && !owner?

      authorized?("automations.manage", feature: :automations)
    end

    def destroy?
      return false if record.is_system?

      authorized?("automations.manage", feature: :automations)
    end

    def toggle?
      update?
    end

    def duplicate?
      create?
    end

    def reorder?
      authorized?("automations.manage", feature: :automations)
    end

    def lookups?
      authorized?("automations.read", feature: :automations)
    end
  end
end
