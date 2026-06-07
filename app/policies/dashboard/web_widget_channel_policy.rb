# frozen_string_literal: true

module Dashboard
  class WebWidgetChannelPolicy < ApplicationPolicy
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
  end
end
