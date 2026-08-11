# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class CategoryPolicy < ApplicationPolicy
      def index?
        owner? || can?("help_center_categories.read") || can?("help_center.manage")
      end

      def create?
        owner? || can?("help_center_categories.manage") || can?("help_center.manage")
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