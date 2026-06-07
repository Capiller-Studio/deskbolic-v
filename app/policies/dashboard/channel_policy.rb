# frozen_string_literal: true

module Dashboard
  class ChannelPolicy < ApplicationPolicy
    def index?
      authorized?("inboxes.read")
    end
  end
end
