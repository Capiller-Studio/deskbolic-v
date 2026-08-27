# frozen_string_literal: true

module Dashboard
  class WhatsappChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read", feature: "channels.whatsapp")
    end

    def new?
      create?
    end

    def oauth_authorize?
      create?
    end

    def create?
      authorized?("inboxes.write", feature: "channels.whatsapp", limit: :channels)
    end

    def callback?
      authorized?("inboxes.write", feature: "channels.whatsapp", limit: :channels)
    end

    def edit?
      update?
    end

    def update?
      authorized?("inboxes.write", feature: "channels.whatsapp")
    end

    def destroy?
      authorized?("inboxes.delete", feature: "channels.whatsapp")
    end

    def reconnect?
      authorized?("inboxes.write", feature: "channels.whatsapp")
    end
  end
end
