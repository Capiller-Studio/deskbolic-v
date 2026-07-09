# frozen_string_literal: true

module Dashboard
  class LabelPolicy < ApplicationPolicy
    def index?
      authorized?("labels.read", feature: "labels")
    end

    def show?
      authorized?("labels.read", feature: "labels")
    end

    def create?
      authorized?("labels.manage", feature: "labels")
    end

    def update?
      authorized?("labels.manage", feature: "labels")
    end

    def destroy?
      authorized?("labels.manage", feature: "labels")
    end
  end
end
