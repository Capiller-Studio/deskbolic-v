# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class CategoryPolicy < ApplicationPolicy
      def index?
        authorized?("help_center_categories.read", feature: :help_center_portals) || authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def create?
        authorized?("help_center_categories.manage", feature: :help_center_portals) || authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def update?
        owner? || can?("help_center_categories.manage") || can?("help_center.manage")
      end

      def destroy?
        owner? || can?("help_center_categories.manage") || can?("help_center.manage")
      end
    end
  end
end