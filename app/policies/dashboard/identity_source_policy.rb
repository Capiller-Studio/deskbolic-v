# frozen_string_literal: true

module Dashboard
  class IdentitySourcePolicy < ApplicationPolicy
    def index?
      authorized?("identity_sources.read", feature: :identity_sources)
    end

    def edit?
      authorized?("identity_sources.manage", feature: :identity_sources)
    end

    def update?
      authorized?("identity_sources.manage", feature: :identity_sources)
    end

    def new?
      create?
    end

    def create?
      authorized?("identity_sources.manage", feature: :identity_sources)
    end

    def destroy?
      authorized?("identity_sources.manage", feature: :identity_sources)
    end

    def test_connection?
      authorized?("identity_sources.manage", feature: :identity_sources)
    end
  end
end
