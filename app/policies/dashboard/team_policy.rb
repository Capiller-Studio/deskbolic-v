# frozen_string_literal: true

module Dashboard
  class TeamPolicy < ApplicationPolicy
    def index?
      authorized?("teams.read", feature: :teams)
    end

    def show?
      authorized?("teams.read", feature: :teams)
    end

    def create?
      authorized?("teams.write", feature: :teams, limit: :teams)
    end

    def update?
      authorized?("teams.write", feature: :teams)
    end

    def destroy?
      authorized?("teams.delete", feature: :teams)
    end
  end
end
