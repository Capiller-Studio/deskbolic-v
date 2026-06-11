# frozen_string_literal: true

module Dashboard
  class WebWidgetChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.web_widget")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.web_widget")
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.web_widget")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.web_widget")
    end
  end
end
