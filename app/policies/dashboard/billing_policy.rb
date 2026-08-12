# frozen_string_literal: true

module Dashboard
  class BillingPolicy < ApplicationPolicy
    def show?
      can?("billing.manage")
    end

    def update?
      can?("billing.manage")
    end
  end
end
