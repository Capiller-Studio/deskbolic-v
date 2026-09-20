# frozen_string_literal: true

module Dashboard
  class InboxPolicy < ApplicationPolicy
    def index?
      can?("inboxes.read")
    end

    def show?
      return true if can?("inboxes.read")
      return true if record.is_a?(Inbox) && record.accessible_by?(user)

      false
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

    def update_members?
      can?("inboxes.write")
    end

    def add_member?
      can?("inboxes.write")
    end

    def remove_member?
      can?("inboxes.write")
    end
  end
end
