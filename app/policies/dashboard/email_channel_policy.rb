# frozen_string_literal: true

module Dashboard
  class EmailChannelPolicy < ApplicationPolicy
    def index?
      true
    end

    def new?
      create?
    end

    def create?
      true
    end

    def edit?
      update?
    end

    def update?
      true
    end

    def destroy?
      true
    end

    def test_smtp?
      true
    end

    def test_imap?
      true
    end

    def verify_forwarding?
      true
    end
  end
end
