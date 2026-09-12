# frozen_string_literal: true

module Dashboard
  class ContactFormChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.contact_form")
    end

    def new?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.contact_form", limit: :channels)
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.contact_form")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.contact_form")
    end
  end
end
