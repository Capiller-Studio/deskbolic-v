# frozen_string_literal: true

module Dashboard
  class InboxPolicy < ApplicationPolicy
    def index?
      can?("inboxes.read")
    end

    def show?
      can?("inboxes.read")
    end

    def create?
      can?("inboxes.write")
    end

    def update?
      can?("inboxes.write")
    end

    def destroy?
      can?("inboxes.delete")
    end
  end
end
