# frozen_string_literal: true

module Dashboard
  class SsoPolicy < ApplicationPolicy
    def show?
      authorized?("sso.read", feature: :sso)
    end

    def update?
      authorized?("sso.manage", feature: :sso)
    end
  end
end
