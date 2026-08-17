# frozen_string_literal: true

module Dashboard
  class ReportPolicy < ApplicationPolicy
    def index?
      can?("reports.view")
    end

    def show?
      can?("reports.view")
    end

    def export?
      can?("reports.export")
    end
  end
end
