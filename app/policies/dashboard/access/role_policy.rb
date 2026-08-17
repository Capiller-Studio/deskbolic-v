# frozen_string_literal: true

module Dashboard
  module Access
    class RolePolicy < ApplicationPolicy
      def index?
        authorized?("roles.read", feature: :roles)
      end

      def show?
        index?
      end

      def create?
        authorized?("roles.manage", feature: :custom_roles)
      end

      def update?
        return false if record.system_provided? && !owner?

        feature_check = record.system_provided? ? :roles : :custom_roles
        authorized?("roles.manage", feature: feature_check)
      end

      def destroy?
        return false if record.system_provided?

        authorized?("roles.manage", feature: :custom_roles)
      end
    end
  end
end
