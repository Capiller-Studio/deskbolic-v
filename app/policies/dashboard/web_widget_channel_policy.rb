# frozen_string_literal: true

module Dashboard
  class WebWidgetChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write")
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write")
    end

    def destroy?
      authorized?("inboxes.delete")
    end
  end
end
