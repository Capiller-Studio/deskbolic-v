# frozen_string_literal: true

module Dashboard
  class ApiChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.api")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.api")
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.api")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.api")
    end
  end
end
