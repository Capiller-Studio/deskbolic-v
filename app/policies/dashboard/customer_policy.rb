# frozen_string_literal: true

module Dashboard
  class CustomerPolicy < ApplicationPolicy
    def index?
      can?("customers.read")
    end

    def show?
      can?("customers.read")
    end

    def create?
      authorized?("customers.write", limit: :customers)
    end

    def update?
      can?("customers.write")
    end

    def destroy?
      can?("customers.delete")
    end
  end
end
