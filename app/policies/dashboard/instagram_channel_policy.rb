# frozen_string_literal: true

module Dashboard
  class InstagramChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.instagram")
    end

    def new?
      create?
    end

    def oauth_authorize?
      authorized?("inboxes.write", feature: "channels.instagram")
    end

    def create?
      authorized?("inboxes.write", feature: "channels.instagram")
    end

    def callback?
      authorized?("inboxes.write", feature: "channels.instagram")
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.instagram")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.instagram")
    end
  end
end
