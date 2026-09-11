# frozen_string_literal: true

module Dashboard
  class CustomChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.custom")
    end

    def show?
      index?
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.custom", limit: :channels)
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.custom")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.custom")
    end

    def test_outgoing_webhook?
      update?
    end

    def test_incoming_webhook?
      update?
    end
  end
end
