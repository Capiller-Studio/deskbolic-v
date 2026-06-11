# frozen_string_literal: true

module Dashboard
  class EmailChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.email")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.email")
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.email")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.email")
    end

    def test_smtp?
      authorized?("inboxes.write")
    end

    def test_imap?
      authorized?("inboxes.write")
    end

    def verify_forwarding?
      authorized?("inboxes.write")
    end
  end
end
