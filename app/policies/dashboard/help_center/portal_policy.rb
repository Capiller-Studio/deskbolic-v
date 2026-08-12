# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class PortalPolicy < ApplicationPolicy
      def index?
        authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def create?
        authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def edit?
        authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def update?
        authorized?("help_center_portals.manage", feature: :help_center_portals)
      end
    end
  end
end
