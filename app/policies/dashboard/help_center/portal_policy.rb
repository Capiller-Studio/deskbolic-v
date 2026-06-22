# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class PortalPolicy < ApplicationPolicy
      def index?
        owner? || can?("inboxes.read")
      end

      def create?
        owner? || can?("inboxes.write")
      end
    end
  end
end
