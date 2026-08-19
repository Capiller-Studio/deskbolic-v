# frozen_string_literal: true

module Dashboard
  class SlaPolicyPolicy < ApplicationPolicy
    def index?
      can?("sla_policies.read")
    end

    def show?
      can?("sla_policies.read")
    end

    def create?
      authorized?("sla_policies.manage", limit: :sla_policies)
    end

    def update?
      can?("sla_policies.manage")
    end

    def destroy?
      can?("sla_policies.manage")
    end

    def reorder?
      can?("sla_policies.manage")
    end
  end
end
