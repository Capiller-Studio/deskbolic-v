# frozen_string_literal: true

module Dashboard
  class FacebookChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.facebook")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.facebook", limit: :channels)
    end

    def callback?
      authorized?("inboxes.write", feature: "channels.facebook", limit: :channels)
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.facebook")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.facebook")
    end

    def reconnect?
      authorized?("inboxes.write", feature: "channels.facebook")
    end
  end
end
