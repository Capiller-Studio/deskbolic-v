# frozen_string_literal: true

module Dashboard
  class MobileWidgetChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.mobile_widget")
    end

    def show?
      index?
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.mobile_widget", limit: :channels)
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.mobile_widget")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.mobile_widget")
    end

    def regenerate_secret?
      update?
    end

    def test_push?
      update?
    end
  end
end
