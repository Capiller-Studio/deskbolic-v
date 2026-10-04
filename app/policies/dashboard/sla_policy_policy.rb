# frozen_string_literal: true

module Dashboard
  class SlaPolicyPolicy < ApplicationPolicy
    def index?
      authorized?("sla_policies.read", feature: :sla)
    end

    def show?
      authorized?("sla_policies.read", feature: :sla)
    end

    def create?
      authorized?("sla_policies.manage", feature: :sla, limit: :sla_policies)
    end

    def update?
      authorized?("sla_policies.manage", feature: :sla)
    end

    def destroy?
      authorized?("sla_policies.manage", feature: :sla)
    end

    def reorder?
      authorized?("sla_policies.manage", feature: :sla)
    end
  end
end
