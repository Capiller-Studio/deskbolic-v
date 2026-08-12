# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class ArticlePolicy < ApplicationPolicy
      def index?
        authorized?("help_center_articles.read", feature: :help_center_portals) || authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def show?
        index?
      end

      def create?
        authorized?("help_center_articles.manage", feature: :help_center_portals) || authorized?("help_center_portals.manage", feature: :help_center_portals)
      end

      def update?
        create?
      end

      def destroy?
        create?
      end

      def publish?
        update?
      end

      def discard_draft?
        update?
      end

      def copy_locale?
        update?
      end
    end
  end
end
