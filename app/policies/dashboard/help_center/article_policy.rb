# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class ArticlePolicy < ApplicationPolicy
      def index?
        owner? || can?("help_center_articles.read") || can?("help_center.manage")
      end

      def show?
        index?
      end

      def create?
        owner? || can?("help_center_articles.manage") || can?("help_center.manage")
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
