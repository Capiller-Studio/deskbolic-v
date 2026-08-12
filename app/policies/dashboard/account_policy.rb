# frozen_string_literal: true

module Dashboard
  class AccountPolicy < ApplicationPolicy
    def show?
      can?("account.manage")
    end

    def update?
      can?("account.manage")
    end
  end
end
