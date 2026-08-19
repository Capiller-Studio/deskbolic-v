# frozen_string_literal: true

module Dashboard
  class DomainPolicy < ApplicationPolicy
    def index?
      authorized?("domains.read", feature: :custom_domains)
    end

    def show?
      authorized?("domains.read", feature: :custom_domains)
    end

    def create?
      authorized?("domains.manage", feature: :custom_domains, limit: :custom_domains)
    end

    def update?
      authorized?("domains.manage", feature: :custom_domains)
    end

    def destroy?
      authorized?("domains.manage", feature: :custom_domains)
    end
  end
end
