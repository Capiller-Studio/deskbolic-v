# frozen_string_literal: true

module Dashboard
  class SettingPolicy < ApplicationPolicy
    def show?
      can?("settings.manage")
    end

    def update?
      can?("settings.manage")
    end
  end
end
