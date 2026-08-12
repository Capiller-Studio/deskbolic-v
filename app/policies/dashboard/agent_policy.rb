# frozen_string_literal: true

module Dashboard
  class AgentPolicy < ApplicationPolicy
    def index?
      can?("agents.read")
    end

    def show?
      can?("agents.read")
    end

    def create?
      can?("agents.invite")
    end

    def update?
      can?("agents.manage")
    end

    def destroy?
      can?("agents.remove")
    end
  end
end
